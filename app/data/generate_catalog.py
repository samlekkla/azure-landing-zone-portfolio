import subprocess
import sys

def install(package):
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])

try:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
    from reportlab.lib.enums import TA_LEFT, TA_CENTER
except ImportError:
    install('reportlab')
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
    from reportlab.lib.enums import TA_LEFT, TA_CENTER

doc = SimpleDocTemplate(
    'app/data/catalog.pdf',
    pagesize=A4,
    rightMargin=2*cm,
    leftMargin=2*cm,
    topMargin=2*cm,
    bottomMargin=2*cm
)

styles = getSampleStyleSheet()
style_title = ParagraphStyle('Title', fontSize=24, spaceAfter=12, textColor=colors.HexColor('#1a3a5c'), alignment=TA_CENTER)
style_h1 = ParagraphStyle('H1', fontSize=16, spaceAfter=8, spaceBefore=16, textColor=colors.HexColor('#1a3a5c'))
style_h2 = ParagraphStyle('H2', fontSize=13, spaceAfter=6, spaceBefore=12, textColor=colors.HexColor('#2e6da4'))
style_body = ParagraphStyle('Body', fontSize=10, spaceAfter=4, leading=14)
style_price = ParagraphStyle('Price', fontSize=11, spaceAfter=6, textColor=colors.HexColor('#2e6da4'))

content = []

content.append(Paragraph('Nordlux Outfitters', style_title))
content.append(Paragraph('Product Catalog 2026', style_title))
content.append(Spacer(1, 0.5*cm))
content.append(HRFlowable(width='100%', thickness=2, color=colors.HexColor('#1a3a5c')))
content.append(Spacer(1, 0.5*cm))

sections = [
    ('About Nordlux Outfitters', [
        'Founded in Stockholm in 1987, Nordlux Outfitters crafts premium outdoor apparel for Scandinavian conditions. Every product is tested on the Swedish fjällen before it reaches the customer.'
    ]),
    ('Jackets', None),
    ('Alpine Trail Jacket (NL-J001)', [
        'Waterproof, windproof, and breathable 3-layer shell.',
        'Material: 75D recycled nylon, 28,000mm waterproof rating',
        'Features: Helmet-compatible hood, pit zips, 4 pockets',
        'Sizes: XS–3XL | Price: 2,499 SEK',
        'Best for: Alpine hiking, ski touring, winter trekking'
    ]),
    ('Fjord Softshell Jacket (NL-J002)', [
        'Stretchy softshell for high-output activities in mild conditions.',
        'Material: 4-way stretch polyester, DWR finish',
        'Features: Flatlock seams, thumb loops, chest pocket',
        'Sizes: XS–XXL | Price: 1,799 SEK',
        'Best for: Trail running, climbing approach, cycling'
    ]),
    ('Footwear', None),
    ('Nordic Hiking Boots (NL-F001)', [
        'Full-grain leather upper with Vibram Megagrip outsole.',
        'Features: Gore-Tex lining, cushioned midsole, wide toe box',
        'Waterproof: Yes | Sizes: EU 36–48 | Price: 1,899 SEK',
        'Best for: Multi-day trekking, wet terrain, technical trails'
    ]),
    ('Summit Trail Runner (NL-F002)', [
        'Lightweight trail running shoe for fast and light adventures.',
        'Material: Mesh upper, rock plate protection',
        'Features: Drainage ports, aggressive lug pattern',
        'Sizes: EU 36–47 | Price: 1,299 SEK',
        'Best for: Trail running, fastpacking, day hikes'
    ]),
    ('Midlayers', None),
    ('Fjord Fleece Pullover (NL-M001)', [
        'Classic fleece made from 100% recycled polyester.',
        'Weight: 280g/m\xb2 | Features: Quarter zip, kangaroo pocket',
        'Sizes: XS–3XL | Price: 899 SEK',
        'Best for: Camp layer, cold weather base, everyday wear'
    ]),
    ('PrimaLoft Vest (NL-M002)', [
        'Insulated vest for core warmth without bulk.',
        'Insulation: PrimaLoft Gold 133g',
        'Features: Packable, water-resistant shell',
        'Sizes: XS–XXL | Price: 1,199 SEK',
        'Best for: Layering system, shoulder season, travel'
    ]),
    ('Packs', None),
    ('Summit Backpack 40L (NL-P001)', [
        'Technical pack for multi-day alpine adventures.',
        'Features: Ventilated back panel, rain cover, ice axe loop, hydration sleeve',
        'Weight: 1.4kg | Price: 1,299 SEK',
        'Best for: Multi-day hiking, ski touring, alpine climbing'
    ]),
    ('Ultralight Day Pack 18L (NL-P002)', [
        'Minimalist pack for fast and light day trips.',
        'Features: Packable, mesh back panel, trekking pole attachment',
        'Weight: 380g | Price: 599 SEK',
        'Best for: Day hikes, trail running, travel'
    ]),
    ('Trail Buddy AI Assistant', [
        'Trail Buddy is Nordlux\'s AI-powered product advisor.',
        'Ask Trail Buddy: Which jacket is best for ski touring in -15\xb0C?',
        'Ask Trail Buddy: What boot should I buy for a 7-day trekking trip in Norway?',
        'Powered by Azure OpenAI + Azure AI Search — RAG architecture.'
    ]),
]

for title, items in sections:
    if items is None:
        content.append(Spacer(1, 0.3*cm))
        content.append(HRFlowable(width='100%', thickness=1, color=colors.HexColor('#cccccc')))
        content.append(Paragraph(title, style_h1))
    else:
        content.append(Paragraph(title, style_h2))
        for item in items:
            content.append(Paragraph(item, style_body))
    content.append(Spacer(1, 0.2*cm))

doc.build(content)
print('catalog.pdf generated successfully at app/data/catalog.pdf')
