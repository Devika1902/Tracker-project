#!/usr/bin/env python3
"""Build the Excel workbook and CSV extracts from the project JSON (stdlib only)."""
from __future__ import annotations

import csv
import json
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "data" / "project.json").read_text(encoding="utf-8"))
OUT = ROOT / "data"
EXPORTS = OUT / "exports"

SHEETS = [
    ("Project Tasks", "tasks", [
        ("Task ID", "id"), ("Task Name", "name"), ("Team", "team"),
        ("Owner", "owner"), ("Due Date", "dueDate"), ("Status", "status"),
        ("Progress %", "progress"), ("Depends On Task ID", "dependencyId"),
        ("Priority", "priority"),
    ]),
    ("Dependencies", "dependencies", [
        ("Task ID", "taskId"), ("Depends On Task ID", "dependsOnTaskId"),
        ("Dependency Status", "status"),
    ]),
    ("Issues", "issues", [
        ("Issue ID", "id"), ("Title", "title"), ("Description", "description"),
        ("Severity", "severity"), ("Owner", "owner"), ("Team", "team"),
        ("Status", "status"), ("Target Date", "targetDate"), ("Business Impact", "impact"),
    ]),
    ("Milestones", "milestones", [
        ("Milestone ID", "id"), ("Milestone", "name"), ("Planned Date", "plannedDate"),
        ("Actual Date", "actualDate"), ("Status", "status"), ("Owner Team", "owner"),
    ]),
]


def col_letter(n: int) -> str:
    out = ""
    while n:
        n, rem = divmod(n - 1, 26)
        out = chr(65 + rem) + out
    return out


def write_csvs() -> None:
    EXPORTS.mkdir(parents=True, exist_ok=True)
    for sheet_name, key, columns in SHEETS:
        path = EXPORTS / (key + ".csv")
        with path.open("w", newline="", encoding="utf-8-sig") as f:
            writer = csv.writer(f)
            writer.writerow([label for label, _ in columns])
            writer.writerows([[row.get(field, "") for _, field in columns] for row in DATA[key]])


def worksheet_xml(key: str, columns: list[tuple[str, str]]) -> str:
    records = DATA[key]
    rows = []
    for row_num, values in enumerate(
        [[label for label, _ in columns]] + [[r.get(field, "") for _, field in columns] for r in records], 1
    ):
        cells = []
        for col_num, value in enumerate(values, 1):
            ref = f"{col_letter(col_num)}{row_num}"
            if row_num == 1:
                cells.append(f'<c r="{ref}" s="1" t="inlineStr"><is><t>{escape(str(value))}</t></is></c>')
            elif isinstance(value, (int, float)):
                cells.append(f'<c r="{ref}"><v>{value}</v></c>')
            else:
                cells.append(f'<c r="{ref}" t="inlineStr"><is><t xml:space="preserve">{escape(str(value))}</t></is></c>')
        rows.append(f'<row r="{row_num}">{"".join(cells)}</row>')
    last = f"{col_letter(len(columns))}{len(records) + 1}"
    widths = "".join(f'<col min="{i}" max="{i}" width="{min(max(len(label) + 3, 15), 48)}" customWidth="1"/>' for i, (label, _) in enumerate(columns, 1))
    return (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            f'<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            f'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            f'<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
            f'<cols>{widths}</cols><sheetData>{"".join(rows)}</sheetData><autoFilter ref="A1:{last}"/>'
            f'</worksheet>')


def write_workbook() -> None:
    names = [s[0] for s in SHEETS]
    content_overrides = ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1, len(SHEETS) + 1))
    sheets = ''.join(f'<sheet name="{escape(name)}" sheetId="{i}" r:id="rId{i}"/>' for i, name in enumerate(names, 1))
    rels = ''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1, len(SHEETS) + 1))
    rels += f'<Relationship Id="rId{len(SHEETS)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    workbook = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                f'<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
                f'<bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews><sheets>{sheets}</sheets></workbook>')
    styles = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
              '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
              '<fonts count="2"><font><sz val="11"/><name val="Aptos"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Aptos"/></font></fonts>'
              '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF197C70"/><bgColor indexed="64"/></patternFill></fill></fills>'
              '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
              '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
              '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
              '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>')
    types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
             '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
             '<Default Extension="xml" ContentType="application/xml"/>'
             '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
             '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
             f'{content_overrides}</Types>')
    root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
                 '</Relationships>')
    target = OUT / "clearing_service_tracker.xlsx"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as book:
        book.writestr("[Content_Types].xml", types)
        book.writestr("_rels/.rels", root_rels)
        book.writestr("xl/workbook.xml", workbook)
        book.writestr("xl/_rels/workbook.xml.rels", f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">{rels}</Relationships>')
        book.writestr("xl/styles.xml", styles)
        for i, (_, key, columns) in enumerate(SHEETS, 1):
            book.writestr(f"xl/worksheets/sheet{i}.xml", worksheet_xml(key, columns))


if __name__ == "__main__":
    write_csvs()
    write_workbook()
    print(f"Created {OUT / 'clearing_service_tracker.xlsx'} and four CSV exports in {EXPORTS}")
