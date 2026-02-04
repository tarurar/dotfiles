#!/usr/bin/env python3
"""
Convert CHANGELOG.md to PDF format.

Usage:
    python changelog_to_pdf.py [input_file] [output_file]

Examples:
    python changelog_to_pdf.py
    python changelog_to_pdf.py CHANGELOG.md commission-service-2.36.3.pdf
"""

import re
import sys
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch


def escape_xml(text):
    """Escape special characters for reportlab's XML parser."""
    text = text.replace('&', '&amp;')
    text = text.replace('<', '&lt;')
    text = text.replace('>', '&gt;')
    return text


def create_styles():
    """Create custom paragraph styles for the PDF."""
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        spaceAfter=12
    )

    h2_style = ParagraphStyle(
        'CustomH2',
        parent=styles['Heading2'],
        fontSize=14,
        spaceBefore=16,
        spaceAfter=8,
        textColor='#1a5276'
    )

    h3_style = ParagraphStyle(
        'CustomH3',
        parent=styles['Heading3'],
        fontSize=11,
        spaceBefore=10,
        spaceAfter=6,
        textColor='#2874a6'
    )

    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontSize=10,
        spaceBefore=2,
        spaceAfter=2
    )

    code_style = ParagraphStyle(
        'CodeBlock',
        parent=styles['Code'],
        fontSize=8,
        leftIndent=20,
        fontName='Courier',
        backColor='#f4f4f4',
        spaceBefore=4,
        spaceAfter=4
    )

    return {
        'title': title_style,
        'h2': h2_style,
        'h3': h3_style,
        'body': body_style,
        'code': code_style
    }


def parse_markdown_to_story(content, styles):
    """Parse markdown content and convert to reportlab story elements."""
    story = []
    lines = content.split('\n')
    in_code_block = False
    code_block_content = []

    for line in lines:
        # Handle code blocks
        if line.startswith('```'):
            if in_code_block:
                # End code block
                if code_block_content:
                    code_text = '\n'.join(code_block_content)
                    story.append(Preformatted(code_text, styles['code']))
                code_block_content = []
                in_code_block = False
            else:
                in_code_block = True
            continue

        if in_code_block:
            code_block_content.append(line)
            continue

        # Skip empty lines
        if not line.strip():
            story.append(Spacer(1, 6))
            continue

        # Handle headings
        if line.startswith('## '):
            text = escape_xml(line[3:])
            story.append(Paragraph(text, styles['h2']))
        elif line.startswith('### '):
            text = escape_xml(line[4:])
            story.append(Paragraph(text, styles['h3']))
        elif line.startswith('# '):
            text = escape_xml(line[2:])
            story.append(Paragraph(text, styles['title']))
        elif line.startswith('* ') or line.startswith('- '):
            text = escape_xml(line[2:])
            # Handle bold text
            text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
            story.append(Paragraph(f"• {text}", styles['body']))
        else:
            text = escape_xml(line)
            # Handle bold text
            text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
            story.append(Paragraph(text, styles['body']))

    return story


def convert_changelog_to_pdf(input_file, output_file):
    """Convert a CHANGELOG.md file to PDF format."""
    # Read the markdown file
    with open(input_file, "r") as f:
        content = f.read()

    # Create PDF document
    doc = SimpleDocTemplate(
        output_file,
        pagesize=A4,
        rightMargin=0.75 * inch,
        leftMargin=0.75 * inch,
        topMargin=0.75 * inch,
        bottomMargin=0.75 * inch
    )

    # Create styles and parse content
    styles = create_styles()
    story = parse_markdown_to_story(content, styles)

    # Build PDF
    doc.build(story)
    print(f"PDF created: {output_file}")


def main():
    input_file = sys.argv[1] if len(sys.argv) > 1 else "CHANGELOG.md"
    output_file = sys.argv[2] if len(sys.argv) > 2 else "CHANGELOG.pdf"

    convert_changelog_to_pdf(input_file, output_file)


if __name__ == "__main__":
    main()
