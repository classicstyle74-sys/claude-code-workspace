#!/usr/bin/env python3
"""Marni テンプレート PPTX 生成スクリプト。

テンプレート (assets/Marni_Template.pptx) のスライドを複製し、
JSON スペックで与えられた内容をプレースホルダーに流し込むことで、
テンプレートのデザイン(レイアウト・フォント・配色・フッター)を
一切変更せずに新しいデッキを組み立てる。

使い方:
    pip install python-pptx   # 未導入の場合
    python3 build_deck.py spec.json [-o output.pptx]

スペック形式は references/slide-types.md を参照。
"""

import argparse
import copy
import json
import sys
import unicodedata
from pathlib import Path

from pptx import Presentation
from pptx.oxml.ns import qn

TEMPLATE_PATH = Path(__file__).resolve().parent.parent / "assets" / "Marni_Template.pptx"

# テンプレート内のスライド番号 (0 始まり) とシェイプ名の対応表。
# シェイプ名は Google Slides エクスポート由来で固定。テンプレートを
# 差し替えない限り変わらない。
SLIDE_TYPES = {
    "cover": {
        "index": 0,
        "shapes": {"title": "Google Shape;133;p18"},
    },
    "toc": {
        "index": 1,
        "shapes": {
            "header": "Google Shape;140;p19",
            "secnum": "Google Shape;141;p19",
            "col_num": "Google Shape;142;p19",
            "col_title": "Google Shape;143;p19",
            "col_page": "Google Shape;144;p19",
        },
    },
    "section_red": {
        "index": 2,
        "shapes": {
            "header": "Google Shape;149;p20",
            "secnum": "Google Shape;151;p20",
        },
    },
    "section_black": {
        "index": 3,
        "shapes": {
            "header": "Google Shape;157;p21",
            "secnum": "Google Shape;159;p21",
        },
    },
    "text_image": {
        "index": 4,
        "shapes": {
            "header": "Google Shape;165;p22",
            "body": "Google Shape;166;p22",
            "image": "Google Shape;167;p22",
            "secnum": "Google Shape;168;p22",
        },
    },
    "two_images": {
        "index": 5,
        "shapes": {
            "header": "Google Shape;177;p23",
            "caption": "Google Shape;175;p23",
            "image_left": "Google Shape;174;p23",
            "image_right": "Google Shape;176;p23",
            "secnum": "Google Shape;178;p23",
        },
    },
    "three_columns": {
        "index": 6,
        "shapes": {
            "header": "Google Shape;184;p24",
            "band_title": "Google Shape;185;p24",
            "subtitles": [
                "Google Shape;186;p24",
                "Google Shape;187;p24",
                "Google Shape;188;p24",
            ],
            "images": [
                "Google Shape;189;p24",
                "Google Shape;190;p24",
                "Google Shape;191;p24",
            ],
            "bodies": [
                "Google Shape;192;p24",
                "Google Shape;193;p24",
                "Google Shape;194;p24",
            ],
            "secnum": "Google Shape;195;p24",
        },
    },
    "quote": {
        "index": 7,
        "shapes": {
            "label": "Google Shape;203;p25",
            "quote": "Google Shape;202;p25",
        },
    },
    "palette": {
        "index": 8,
        "shapes": {
            "header": "Google Shape;209;p26",
            "secnum": "Google Shape;210;p26",
        },
    },
    "closing": {
        "index": 9,
        "shapes": {"title": "Google Shape;229;p27"},
    },
}


def clone_slide(prs, source_slide):
    """テンプレートスライドを末尾に複製する。

    デザイン(背景・ロゴ・フッター)はレイアウト/マスター側にあり、
    同じレイアウトを共有するため自動的に引き継がれる。
    テンプレートのスライド自体は画像 rel を持たない (検証済み) ので
    シェイプ XML の deepcopy だけで完全な複製になる。
    """
    new_slide = prs.slides.add_slide(source_slide.slide_layout)
    for shape in list(new_slide.shapes):
        shape._element.getparent().remove(shape._element)
    for shape in source_slide.shapes:
        new_slide.shapes._spTree.append(copy.deepcopy(shape._element))
    return new_slide


def delete_slide(prs, slide):
    """スライドを sldIdLst と rel の両方から取り除く。"""
    slide_id = None
    for sld_id in prs.slides._sldIdLst:
        if prs.part.related_part(sld_id.get(qn("r:id"))) is slide.part:
            slide_id = sld_id
            break
    if slide_id is None:
        raise ValueError("slide not found in sldIdLst")
    prs.part.drop_rel(slide_id.get(qn("r:id")))
    prs.slides._sldIdLst.remove(slide_id)


def find_shape(slide, name):
    for shape in slide.shapes:
        if shape.name == name:
            return shape
    raise KeyError(f"shape {name!r} not found on slide")


def fill_text(shape, text):
    """テキストフレームを書き換える。書式は先頭段落・先頭ランを踏襲。

    text 中の改行は段落区切りとして扱う。空文字列なら空段落 1 つ。
    """
    tf = shape.text_frame
    tx_body = tf.paragraphs[0]._p.getparent()
    proto = copy.deepcopy(tf.paragraphs[0]._p)
    proto_runs = proto.findall(qn("a:r"))
    for extra in proto_runs[1:]:
        proto.remove(extra)
    for p in list(tf.paragraphs):
        p._p.getparent().remove(p._p)
    lines = text.split("\n") if text else [""]
    for line in lines:
        p = copy.deepcopy(proto)
        runs = p.findall(qn("a:r"))
        if runs:
            t = runs[0].find(qn("a:t"))
            if t is None:
                t = runs[0].makeelement(qn("a:t"), {})
                runs[0].append(t)
            t.text = line
            if not line:
                p.remove(runs[0])
        tx_body.append(p)


def insert_image(shape, image_path, warnings):
    if not image_path:
        return
    path = Path(image_path)
    if not path.is_file():
        warnings.append(f"画像が見つからないため空欄のままにした: {image_path}")
        return
    try:
        shape.insert_picture(str(path))
    except AttributeError:
        warnings.append(f"シェイプ {shape.name!r} は画像プレースホルダーではない")


def display_width(text):
    """全角文字を 2、半角文字を 1 として数える表示幅。

    references/slide-types.md の文字数目安は半角換算で定義されているため、
    日本語などの全角文字を含む文章を正しく判定するにはこの幅で比較する
    必要がある(単純な len() では全角文の超過を見逃す)。
    """
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def warn_if_long(warnings, label, text, limit):
    if not text:
        return
    width = display_width(text)
    if width > limit:
        warnings.append(
            f"{label} が半角換算 {width} 文字相当あり目安 ({limit} 文字) を超過。"
            "はみ出す可能性があるので内容の分割を検討。"
        )


def build_slide(slide, spec, warnings):
    stype = spec["type"]
    names = SLIDE_TYPES[stype]["shapes"]

    def put(key, value, limit=None, label=None):
        if value is None:
            return
        if limit:
            warn_if_long(warnings, label or f"{stype}.{key}", value, limit)
        fill_text(find_shape(slide, names[key]), value)

    if stype in ("cover", "closing"):
        put("title", spec.get("title"), 60)

    elif stype == "toc":
        put("header", spec.get("title", "Table of Content"), 50)
        put("secnum", spec.get("secnum", "0.0"))
        items = spec.get("items", [])
        if len(items) > 9:
            warnings.append(f"目次が {len(items)} 行。9 行を超えるとはみ出す。")
        for it in items:
            warn_if_long(warnings, "toc 項目", it.get("title", ""), 45)
        put("col_num", "\n".join(it.get("num", "") for it in items))
        put("col_title", "\n".join(it.get("title", "") for it in items))
        put("col_page", "\n".join(it.get("page", "") for it in items))

    elif stype in ("section_red", "section_black", "palette"):
        put("header", spec.get("title"), 50)
        put("secnum", spec.get("secnum"))

    elif stype == "text_image":
        put("header", spec.get("title"), 50)
        put("secnum", spec.get("secnum"))
        put("body", spec.get("body"), 700)
        insert_image(find_shape(slide, names["image"]), spec.get("image"), warnings)

    elif stype == "two_images":
        put("header", spec.get("title"), 50)
        put("secnum", spec.get("secnum"))
        put("caption", spec.get("caption"), 40)
        images = spec.get("images", [])
        for key, img in zip(("image_left", "image_right"), images):
            insert_image(find_shape(slide, names[key]), img, warnings)

    elif stype == "three_columns":
        put("header", spec.get("title"), 50)
        put("secnum", spec.get("secnum"))
        put("band_title", spec.get("band_title"), 60)
        columns = spec.get("columns", [])
        if len(columns) > 3:
            warnings.append("three_columns の列は最大 3。4 列目以降は無視。")
        for i, col in enumerate(columns[:3]):
            if col.get("subtitle") is not None:
                warn_if_long(warnings, f"列{i + 1} subtitle", col["subtitle"], 45)
                fill_text(find_shape(slide, names["subtitles"][i]), col["subtitle"])
            if col.get("body") is not None:
                warn_if_long(warnings, f"列{i + 1} body", col["body"], 120)
                fill_text(find_shape(slide, names["bodies"][i]), col["body"])
            insert_image(
                find_shape(slide, names["images"][i]), col.get("image"), warnings
            )

    elif stype == "quote":
        put("label", spec.get("label", ""))
        put("quote", spec.get("quote"), 220)

    if spec.get("notes"):
        slide.notes_slide.notes_text_frame.text = spec["notes"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", help="スライド定義 JSON ファイル")
    parser.add_argument("-o", "--output", default="deck.pptx", help="出力 PPTX パス")
    parser.add_argument(
        "--template", default=str(TEMPLATE_PATH), help="テンプレート PPTX パス"
    )
    args = parser.parse_args()

    template_path = Path(args.template).resolve()
    output_path = Path(args.output).resolve()
    if output_path == template_path:
        sys.exit(
            f"出力先がテンプレートと同じパスです: {output_path}\n"
            "テンプレートを破壊するため中止。--output に別のパスを指定してください。"
        )

    spec = json.loads(Path(args.spec).read_text(encoding="utf-8"))
    slides_spec = spec["slides"]

    unknown = [s["type"] for s in slides_spec if s["type"] not in SLIDE_TYPES]
    if unknown:
        sys.exit(f"未知のスライドタイプ: {unknown}。有効: {list(SLIDE_TYPES)}")

    prs = Presentation(args.template)
    template_slides = list(prs.slides)
    warnings = []

    for slide_spec in slides_spec:
        source = template_slides[SLIDE_TYPES[slide_spec["type"]]["index"]]
        new_slide = clone_slide(prs, source)
        build_slide(new_slide, slide_spec, warnings)

    for slide in template_slides:
        delete_slide(prs, slide)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    prs.save(str(output_path))

    print(f"OK: {len(slides_spec)} 枚のスライドを {output_path} に生成")
    for w in warnings:
        print(f"WARNING: {w}", file=sys.stderr)


if __name__ == "__main__":
    main()
