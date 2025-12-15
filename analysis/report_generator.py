"""
PDF Report Generator for Breast Cancer Genetic Risk Analysis
Generates professional PDF reports from real VCF analysis results
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import seaborn as sns
import numpy as np
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Image, ListFlowable, ListItem, PageTemplate,
    Frame, FrameBreak, KeepTogether
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY
from reportlab.pdfgen import canvas
import io
import base64

class PDFReportGenerator:
    """Generate professional PDF reports from genetic analysis results"""
    
    def __init__(self, analysis_results: Dict):
        """
        Initialize report generator with analysis results
        
        Args:
            analysis_results: Dictionary containing genetic analysis results
        """
        self.results = analysis_results
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()
        
        # Extract data
        self.patient_id = self.results.get('patient_id', 'N/A')
        self.analysis_date = self.results.get('analysis_date', '')
        self.overall_risk = self.results.get('overall_risk', 'Unknown')
        self.summary = self.results.get('summary', {})
        self.variants = self.results.get('variants', [])
        self.recommendations = self.results.get('recommendations', [])
        self.plots_data = self.results.get('plots', {})
        
        # Statistics
        self.variant_count = self.results.get('variant_count', 0)
        self.pathogenic_count = self.results.get('pathogenic_count', 0)
        self.vus_count = self.results.get('vus_count', 0)
        
        # Create output directory if needed
        self.output_dir = Path("reports")
        self.output_dir.mkdir(exist_ok=True)
    
    def _setup_custom_styles(self):
        """Setup custom paragraph styles"""
        # Title style
        self.styles.add(ParagraphStyle(
            name='Title',
            parent=self.styles['Title'],
            fontSize=24,
            textColor=colors.HexColor('#1E3A8A'),
            spaceAfter=30,
            alignment=TA_CENTER
        ))
        
        # Heading 1 style
        self.styles.add(ParagraphStyle(
            name='Heading1',
            parent=self.styles['Heading1'],
            fontSize=16,
            textColor=colors.HexColor('#1E40AF'),
            spaceBefore=20,
            spaceAfter=10,
            leftIndent=0
        ))
        
        # Heading 2 style
        self.styles.add(ParagraphStyle(
            name='Heading2',
            parent=self.styles['Heading2'],
            fontSize=14,
            textColor=colors.HexColor('#3B82F6'),
            spaceBefore=15,
            spaceAfter=8,
            leftIndent=0
        ))
        
        # Normal text style
        self.styles.add(ParagraphStyle(
            name='NormalIndent',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=colors.black,
            spaceAfter=6,
            leftIndent=20
        ))
        
        # Risk level styles
        self.styles.add(ParagraphStyle(
            name='HighRisk',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=colors.red,
            backColor=colors.HexColor('#FEE2E2'),
            spaceAfter=6
        ))
        
        self.styles.add(ParagraphStyle(
            name='ModerateRisk',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=colors.orange,
            backColor=colors.HexColor('#FEF3C7'),
            spaceAfter=6
        ))
        
        self.styles.add(ParagraphStyle(
            name='VUSRisk',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=colors.purple,
            backColor=colors.HexColor('#F3E8FF'),
            spaceAfter=6
        ))
        
        self.styles.add(ParagraphStyle(
            name='LowRisk',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=colors.green,
            backColor=colors.HexColor('#D1FAE5'),
            spaceAfter=6
        ))
        
        # Footer style
        self.styles.add(ParagraphStyle(
            name='Footer',
            parent=self.styles['Normal'],
            fontSize=8,
            textColor=colors.gray,
            alignment=TA_CENTER
        ))
    
    def generate_pdf_report(self, output_path: str):
        """Generate complete PDF report"""
        doc = SimpleDocTemplate(
            output_path,
            pagesize=A4,
            rightMargin=72,
            leftMargin=72,
            topMargin=72,
            bottomMargin=72
        )
        
        story = []
        
        # Add header
        story.extend(self._create_header())
        
        # Add patient information
        story.extend(self._create_patient_info())
        
        # Add executive summary
        story.extend(self._create_executive_summary())
        
        # Add page break
        story.append(PageBreak())
        
        # Add detailed findings
        story.extend(self._create_detailed_findings())
        
        # Add page break if needed
        if len(self.variants) > 5:
            story.append(PageBreak())
        
        # Add clinical implications
        story.extend(self._create_clinical_implications())
        
        # Add recommendations
        story.extend(self._create_recommendations())
        
        # Add footer to all pages
        def add_footer(canvas, doc):
            canvas.saveState()
            canvas.setFont('Helvetica', 8)
            canvas.setFillColor(colors.gray)
            
            # Page number
            page_num = canvas.getPageNumber()
            canvas.drawRightString(doc.pagesize[0] - 72, 30, f"Page {page_num}")
            
            # Report info
            canvas.drawString(72, 30, 
                            f"Report ID: {self.patient_id}_{datetime.now().strftime('%Y%m%d')}")
            
            # Confidential notice
            canvas.drawCentredString(doc.pagesize[0] / 2, 30, 
                                   "CONFIDENTIAL - For Clinical Use Only")
            
            canvas.restoreState()
        
        # Build the document
        doc.build(story, onFirstPage=add_footer, onLaterPages=add_footer)
        
        print(f"PDF report generated: {output_path}")
        return output_path
    
    def _create_header(self):
        """Create report header"""
        elements = []
        
        # Title
        elements.append(Paragraph(
            "BREAST CANCER GENETIC RISK ASSESSMENT REPORT",
            self.styles['Title']
        ))
        
        # Subtitle
        elements.append(Paragraph(
            "Clinical Genetics Laboratory Analysis",
            ParagraphStyle(
                'Subtitle',
                parent=self.styles['Normal'],
                fontSize=12,
                textColor=colors.HexColor('#4B5563'),
                alignment=TA_CENTER,
                spaceAfter=30
            )
        ))
        
        return elements
    
    def _create_patient_info(self):
        """Create patient information section"""
        elements = []
        
        elements.append(Paragraph(
            "PATIENT INFORMATION",
            self.styles['Heading1']
        ))
        
        # Create patient info table
        patient_data = [
            ["Patient ID:", self.patient_id],
            ["Analysis Date:", self._format_date(self.analysis_date)],
            ["Overall Risk Level:", self.overall_risk],
            ["Report Date:", datetime.now().strftime("%Y-%m-%d %H:%M")]
        ]
        
        patient_table = Table(patient_data, colWidths=[2*inch, 3*inch])
        patient_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#F3F4F6')),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#4B5563')),
            ('FONTWEIGHT', (0, 0), (0, -1), 'Bold'),
        ]))
        
        elements.append(patient_table)
        elements.append(Spacer(1, 20))
        
        # Create statistics table
        stats_data = [
            ["Metric", "Count"],
            ["Variants Analyzed", str(self.variant_count)],
            ["Pathogenic Variants", str(self.pathogenic_count)],
            ["Variants of Uncertain Significance (VUS)", str(self.vus_count)],
            ["Genes with Variants", str(len(self.summary.get('genes_with_variants', [])))],
            ["Total Genes Analyzed", str(self.summary.get('total_genes_analyzed', 0))]
        ]
        
        stats_table = Table(stats_data, colWidths=[3*inch, 1*inch])
        stats_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E40AF')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGNMENT', (1, 0), (1, -1), 'CENTER'),
            ('FONTWEIGHT', (0, 0), (-1, 0), 'Bold'),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
        ]))
        
        elements.append(stats_table)
        elements.append(Spacer(1, 30))
        
        return elements
    
    def _create_executive_summary(self):
        """Create executive summary section"""
        elements = []
        
        elements.append(Paragraph(
            "EXECUTIVE SUMMARY",
            self.styles['Heading1']
        ))
        
        # Risk interpretation
        risk_interpretation = self.summary.get('risk_interpretation', 
                                             'No risk interpretation available.')
        elements.append(Paragraph(
            risk_interpretation,
            ParagraphStyle(
                'RiskSummary',
                parent=self.styles['Normal'],
                fontSize=11,
                textColor=colors.black,
                spaceAfter=12,
                alignment=TA_JUSTIFY
            )
        ))
        
        # Highlight high-risk findings
        high_risk_genes = self.summary.get('high_risk_genes', [])
        if high_risk_genes:
            elements.append(Paragraph(
                "High-Risk Findings:",
                ParagraphStyle(
                    'HighRiskLabel',
                    parent=self.styles['Normal'],
                    fontSize=11,
                    textColor=colors.red,
                    fontWeight='bold',
                    spaceBefore=10,
                    spaceAfter=5
                )
            ))
            
            for gene in high_risk_genes:
                elements.append(Paragraph(
                    f"• Pathogenic variant detected in {gene} gene",
                    self.styles['HighRisk']
                ))
        
        # Create risk level visualization
        if self.plots_data:
            elements.append(Spacer(1, 15))
            elements.extend(self._create_risk_chart())
        
        elements.append(Spacer(1, 20))
        
        return elements
    
    def _create_detailed_findings(self):
        """Create detailed findings section with variant table"""
        elements = []
        
        elements.append(Paragraph(
            "DETAILED GENETIC FINDINGS",
            self.styles['Heading1']
        ))
        
        if not self.variants:
            elements.append(Paragraph(
                "No genetic variants were detected in the analyzed breast cancer genes.",
                self.styles['Normal']
            ))
            return elements
        
        # Create variant table
        table_data = [["Gene", "Position", "Change", "Type", "ClinVar", "Risk Level", "AF"]]
        
        for variant in self.variants[:50]:  # Limit to 50 variants for PDF
            gene = variant.get('gene', '')
            chromosome = variant.get('chromosome', '')
            position = variant.get('position', '')
            ref = variant.get('ref', '')
            alt = variant.get('alt', '')
            consequence = variant.get('consequence', '')
            clinvar = variant.get('clinvar_significance', 'Unknown')
            risk_level = variant.get('risk_level', 'Unknown')
            gnomad_af = variant.get('gnomad_af', 0)
            
            # Format allele frequency
            af_str = 'N/A'
            if gnomad_af:
                af = float(gnomad_af) if not isinstance(gnomad_af, float) else gnomad_af
                if af > 0:
                    af_str = f"{af:.6f}" if af >= 0.0001 else "<0.0001"
            
            # Format variant change
            change = f"{ref}→{alt}"
            if len(ref) > 3 or len(alt) > 3:
                change = 'DEL' if len(ref) > len(alt) else 'INS'
            
            table_data.append([
                gene,
                f"{chromosome}:{position}",
                change,
                consequence.replace('_variant', ''),
                clinvar,
                risk_level,
                af_str
            ])
        
        # Create table
        variant_table = Table(table_data, colWidths=[0.6*inch, 1*inch, 0.6*inch, 
                                                    1.2*inch, 1.2*inch, 1*inch, 0.6*inch])
        
        # Define table style
        table_style = TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E40AF')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGNMENT', (0, 0), (-1, -1), 'CENTER'),
            ('FONTWEIGHT', (0, 0), (-1, 0), 'Bold'),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
        ])
        
        # Apply row coloring based on risk level
        for i, row in enumerate(table_data[1:], start=1):
            risk_level = row[5].lower()
            if 'high' in risk_level:
                table_style.add('BACKGROUND', (0, i), (-1, i), colors.HexColor('#FEE2E2'))
            elif 'vus' in risk_level or 'uncertain' in risk_level:
                table_style.add('BACKGROUND', (0, i), (-1, i), colors.HexColor('#FEF3C7'))
            elif 'moderate' in risk_level:
                table_style.add('BACKGROUND', (0, i), (-1, i), colors.HexColor('#FEF3C7'))
        
        variant_table.setStyle(table_style)
        
        elements.append(variant_table)
        elements.append(Spacer(1, 10))
        
        # Add note about limited display
        if len(self.variants) > 50:
            elements.append(Paragraph(
                f"Note: Displaying first 50 of {len(self.variants)} variants. "
                "Full variant list is available in the electronic report.",
                ParagraphStyle(
                    'TableNote',
                    parent=self.styles['Normal'],
                    fontSize=8,
                    textColor=colors.gray,
                    fontStyle='italic'
                )
            ))
        
        elements.append(Spacer(1, 20))
        
        return elements
    
    def _create_clinical_implications(self):
        """Create clinical implications section"""
        elements = []
        
        elements.append(Paragraph(
            "CLINICAL IMPLICATIONS",
            self.styles['Heading1']
        ))
        
        clinical_implications = self.summary.get('clinical_implications', [])
        
        if not clinical_implications:
            elements.append(Paragraph(
                "No specific clinical implications based on the genetic findings.",
                self.styles['Normal']
            ))
            return elements
        
        # Create bullet list
        bullet_items = []
        for implication in clinical_implications:
            bullet_items.append(ListItem(
                Paragraph(implication, self.styles['NormalIndent']),
                leftIndent=20,
                bulletColor=colors.HexColor('#3B82F6'),
                value='bullet'
            ))
        
        elements.append(ListFlowable(
            bullet_items,
            bulletType='bullet',
            start='square',
            leftIndent=40,
            bulletFontSize=8,
            bulletColor=colors.HexColor('#3B82F6')
        ))
        
        elements.append(Spacer(1, 20))
        
        return elements
    
    def _create_recommendations(self):
        """Create recommendations section"""
        elements = []
        
        elements.append(Paragraph(
            "CLINICAL RECOMMENDATIONS",
            self.styles['Heading1']
        ))
        
        if not self.recommendations:
            elements.append(Paragraph(
                "No specific recommendations based on the genetic findings.",
                self.styles['Normal']
            ))
            return elements
        
        # Create priority-based recommendations
        for rec in self.recommendations:
            priority = rec.get('priority', 'medium').lower()
            recommendation = rec.get('recommendation', '')
            rationale = rec.get('rationale', '')
            
            # Choose style based on priority
            style_name = 'Normal'
            if priority == 'high':
                style_name = 'HighRisk'
            elif priority == 'medium':
                style_name = 'ModerateRisk'
            elif priority == 'low':
                style_name = 'LowRisk'
            
            # Priority badge
            elements.append(Paragraph(
                f"[{priority.upper()}] {recommendation}",
                self.styles[style_name]
            ))
            
            # Rationale (indented)
            if rationale:
                elements.append(Paragraph(
                    f"Rationale: {rationale}",
                    ParagraphStyle(
                        'Rationale',
                        parent=self.styles['Normal'],
                        fontSize=9,
                        textColor=colors.HexColor('#6B7280'),
                        leftIndent=20,
                        fontStyle='italic',
                        spaceAfter=8
                    )
                ))
        
        elements.append(Spacer(1, 30))
        
        # Add disclaimer
        elements.append(Paragraph(
            "DISCLAIMER: This report is intended for clinical use only. "
            "All findings should be interpreted by a qualified genetic counselor "
            "or healthcare professional in the context of the patient's personal "
            "and family history.",
            ParagraphStyle(
                'Disclaimer',
                parent=self.styles['Normal'],
                fontSize=8,
                textColor=colors.gray,
                alignment=TA_JUSTIFY,
                fontStyle='italic',
                borderWidth=1,
                borderColor=colors.grey,
                borderPadding=5,
                borderRadius=3,
                backColor=colors.HexColor('#F9FAFB')
            )
        ))
        
        return elements
    
    def _create_risk_chart(self):
        """Create risk distribution chart for PDF"""
        elements = []
        
        try:
            # Get risk distribution data
            risk_data = self.plots_data.get('risk_distribution', {})
            
            if not risk_data:
                return elements
            
            # Create matplotlib figure
            plt.figure(figsize=(6, 4))
            
            labels = []
            sizes = []
            colors_list = []
            
            # Prepare data
            for risk, count in risk_data.items():
                if count > 0:
                    labels.append(risk)
                    sizes.append(float(count))
                    # Assign colors
                    if 'high' in risk.lower():
                        colors_list.append('#EF4444')  # red
                    elif 'vus' in risk.lower():
                        colors_list.append('#F59E0B')  # orange
                    else:
                        colors_list.append('#10B981')  # green
            
            # Create pie chart
            if sizes:
                plt.pie(sizes, labels=labels, colors=colors_list, autopct='%1.1f%%', startangle=90)
                plt.title('Variant Risk Distribution', fontsize=12, fontweight='bold')
                plt.axis('equal')
                
                # Save to buffer
                buf = io.BytesIO()
                plt.savefig(buf, format='png', dpi=150, bbox_inches='tight')
                plt.close()
                
                # Create ReportLab Image
                buf.seek(0)
                img = Image(buf, width=4*inch, height=2.5*inch)
                img.hAlign = 'CENTER'
                
                elements.append(img)
                elements.append(Spacer(1, 10))
                
        except Exception as e:
            print(f"Error creating risk chart: {e}")
            elements.append(Paragraph(
                "Risk distribution chart not available.",
                self.styles['Normal']
            ))
        
        return elements
    
    def _format_date(self, date_string: str) -> str:
        """Format date string for display"""
        try:
            if not date_string:
                return "N/A"
            dt = datetime.fromisoformat(date_string.replace('Z', '+00:00'))
            return dt.strftime("%Y-%m-%d %H:%M")
        except:
            return str(date_string)[:19]  # Truncate if can't parse
    
    def generate_json_report(self, output_path: str):
        """Generate JSON report file"""
        with open(output_path, 'w') as f:
            json.dump(self.results, f, indent=2, default=str)
        
        print(f"JSON report generated: {output_path}")
        return output_path
    
    def generate_html_report(self, output_path: str):
        """Generate HTML report file"""
        html_template = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Breast Cancer Genetic Risk Report - {self.patient_id}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; }}
                .header {{ text-align: center; border-bottom: 2px solid #1E40AF; padding-bottom: 20px; }}
                .title {{ color: #1E3A8A; font-size: 24px; font-weight: bold; }}
                .section {{ margin-top: 30px; }}
                .section-title {{ color: #1E40AF; font-size: 18px; border-bottom: 1px solid #ccc; padding-bottom: 5px; }}
                .table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
                .table th {{ background-color: #1E40AF; color: white; padding: 8px; text-align: left; }}
                .table td {{ padding: 8px; border: 1px solid #ddd; }}
                .high-risk {{ background-color: #FEE2E2; color: #991B1B; }}
                .vus-risk {{ background-color: #FEF3C7; color: #92400E; }}
                .footer {{ margin-top: 40px; font-size: 12px; color: #666; text-align: center; }}
            </style>
        </head>
        <body>
            <div class="header">
                <div class="title">BREAST CANCER GENETIC RISK ASSESSMENT REPORT</div>
                <div>Clinical Genetics Laboratory Analysis</div>
            </div>
            
            <div class="section">
                <div class="section-title">PATIENT INFORMATION</div>
                <p><strong>Patient ID:</strong> {self.patient_id}</p>
                <p><strong>Analysis Date:</strong> {self._format_date(self.analysis_date)}</p>
                <p><strong>Overall Risk Level:</strong> {self.overall_risk}</p>
            </div>
            
            <div class="section">
                <div class="section-title">EXECUTIVE SUMMARY</div>
                <p>{self.summary.get('risk_interpretation', '')}</p>
            </div>
            
            <div class="section">
                <div class="section-title">GENETIC FINDINGS</div>
                <p>Total Variants Analyzed: {self.variant_count}</p>
                <p>Pathogenic Variants: {self.pathogenic_count}</p>
                <p>VUS: {self.vus_count}</p>
            </div>
            
            <div class="footer">
                <p>Report generated on {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>
                <p>CONFIDENTIAL - For Clinical Use Only</p>
            </div>
        </body>
        </html>
        """
        
        with open(output_path, 'w') as f:
            f.write(html_template)
        
        print(f"HTML report generated: {output_path}")
        return output_path

# Helper function for quick report generation
def generate_quick_report(analysis_results: Dict, output_dir: str = "reports") -> Dict:
    """Generate all report formats quickly"""
    Path(output_dir).mkdir(exist_ok=True)
    
    patient_id = analysis_results.get('patient_id', 'UNKNOWN')
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    generator = PDFReportGenerator(analysis_results)
    
    # Generate reports
    pdf_file = generator.generate_pdf_report(
        f"{output_dir}/{patient_id}_report_{timestamp}.pdf"
    )
    
    json_file = generator.generate_json_report(
        f"{output_dir}/{patient_id}_data_{timestamp}.json"
    )
    
    html_file = generator.generate_html_report(
        f"{output_dir}/{patient_id}_summary_{timestamp}.html"
    )
    
    return {
        'pdf': pdf_file,
        'json': json_file,
        'html': html_file,
        'patient_id': patient_id,
        'timestamp': timestamp
    }

if __name__ == "__main__":
    # Test the report generator
    sample_results = {
        'patient_id': 'TEST001',
        'analysis_date': datetime.now().isoformat(),
        'overall_risk': 'High Risk',
        'variant_count': 12,
        'pathogenic_count': 2,
        'vus_count': 3,
        'summary': {
            'risk_interpretation': 'Detected pathogenic variants in BRCA1 and BRCA2 genes.',
            'clinical_implications': [
                'High lifetime risk of breast cancer',
                'Increased risk of ovarian cancer'
            ],
            'high_risk_genes': ['BRCA1', 'BRCA2'],
            'genes_with_variants': ['BRCA1', 'BRCA2', 'PALB2'],
            'total_genes_analyzed': 15
        },
        'variants': [
            {
                'gene': 'BRCA1',
                'chromosome': '17',
                'position': 43091995,
                'ref': 'AG',
                'alt': 'A',
                'consequence': 'frameshift_variant',
                'clinvar_significance': 'Pathogenic',
                'risk_level': 'High Risk',
                'gnomad_af': 0.0001
            }
        ],
        'recommendations': [
            {
                'priority': 'high',
                'recommendation': 'Referral to genetic counseling',
                'rationale': 'Pathogenic BRCA1 variant detected'
            }
        ],
        'plots': {
            'risk_distribution': {
                'High Risk': 2,
                'VUS': 3,
                'Low Risk': 7
            }
        }
    }
    
    generator = PDFReportGenerator(sample_results)
    generator.generate_pdf_report("test_report.pdf")
    print("Test report generated: test_report.pdf")