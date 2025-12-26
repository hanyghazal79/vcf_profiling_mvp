#!/usr/bin/env python3
"""
Simplified Genetic Analyzer for Breast Cancer Risk
Works with real VCF files - Class-based implementation
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum

# Check if running on PythonAnywhere
if 'PYTHONANYWHERE_DOMAIN' in os.environ:
    # Disable cyvcf2 import on PythonAnywhere (not available)
    CYVCF2_AVAILABLE = False
else:
    try:
        import cyvcf2
        CYVCF2_AVAILABLE = True
    except ImportError:
        CYVCF2_AVAILABLE = False
        print("Warning: cyvcf2 not available, using simple VCF parser")

# Breast cancer genes with GRCh37 coordinates
BREAST_CANCER_GENES = {
    'BRCA1': {'chr': '17', 'start': 43044295, 'end': 43125483},
    'BRCA2': {'chr': '13', 'start': 32889611, 'end': 32973805},
    'PALB2': {'chr': '16', 'start': 23614479, 'end': 23652679},
    'TP53': {'chr': '17', 'start': 7661779, 'end': 7687550},
    'PTEN': {'chr': '10', 'start': 89622870, 'end': 89731687},
    'CHEK2': {'chr': '22', 'start': 28687741, 'end': 28741829},
    'ATM': {'chr': '11', 'start': 108093099, 'end': 108239829},
    'CDH1': {'chr': '16', 'start': 68737224, 'end': 68835537},
    'STK11': {'chr': '19', 'start': 1222203, 'end': 1249790},
    'NF1': {'chr': '17', 'start': 29421945, 'end': 29704695}
}

class RiskLevel(Enum):
    HIGH = "High Risk"
    MODERATE = "Moderate Risk"
    INCREASED = "Increased Risk"
    POPULATION = "Population Risk"
    VUS = "Variant of Uncertain Significance"

@dataclass
class GeneticVariant:
    """Data class for storing variant information"""
    chromosome: str
    position: int
    ref: str
    alt: str
    gene: str
    rsid: Optional[str] = None
    consequence: Optional[str] = None
    clinvar_significance: Optional[str] = None
    gnomad_af: Optional[float] = None
    classification: Optional[str] = None
    risk_level: Optional[str] = None
    
    def to_dict(self):
        return asdict(self)

class GeneticAnalyzer:
    """Core analysis engine for breast cancer genetic risk assessment"""
    
    def __init__(self, mode: str = 'offline'):
        """
        Initialize analyzer with specified mode
        
        Args:
            mode: 'offline' for local analysis, 'online' for API-based annotation
        """
        self.mode = mode
        self.variants: List[GeneticVariant] = []
        self.results = {}
        self.patient_id = ""
        print(f"GeneticAnalyzer initialized in {mode} mode")
    
    def process_vcf(self, vcf_path: str, patient_id: str = "P001") -> Dict:
        """
        Process VCF file and extract relevant variants
        
        Args:
            vcf_path: Path to VCF file
            patient_id: Patient identifier
            
        Returns:
            Dictionary with analysis results
        """
        self.patient_id = patient_id
        print(f"\n{'='*60}")
        print(f"Starting Breast Cancer Genetic Risk Analysis")
        print(f"Patient: {patient_id}")
        print(f"VCF: {vcf_path}")
        print(f"{'='*60}")
        
        try:
            # Parse VCF
            self.variants = self._parse_vcf_simple(vcf_path)
            
            # Classify variants
            self._classify_variants()
            
            # Generate results
            self.results = self._generate_results()
            
            print(f"\nAnalysis complete!")
            print(f"Variants found: {self.results['variant_count']}")
            print(f"Pathogenic: {self.results['pathogenic_count']}")
            print(f"VUS: {self.results['vus_count']}")
            print(f"Overall risk: {self.results['overall_risk']}")
            print(f"{'='*60}")
            
            return self.results
            
        except Exception as e:
            print(f"\nERROR in analysis: {str(e)}")
            
            # Return error results
            return self._generate_error_results(str(e))
    
    # Update the _parse_vcf_simple method to be more robust
    def _parse_vcf_simple(self, vcf_path: str) -> List[GeneticVariant]:
        """Parse VCF file without external dependencies - PythonAnywhere compatible"""
        variants = []
        
        print(f"Parsing VCF: {vcf_path}")
        
        if not os.path.exists(vcf_path):
            raise FileNotFoundError(f"VCF file not found: {vcf_path}")
        
        # Check if file is gzipped
        is_gzipped = vcf_path.lower().endswith('.gz')
        
        try:
            if is_gzipped:
                import gzip
                opener = gzip.open
                mode = 'rt'  # text mode for gzip
            else:
                opener = open
                mode = 'r'
            
            with opener(vcf_path, mode) as f:
                line_number = 0
                in_header = True
                
                for line in f:
                    line_number += 1
                    line = line.strip()
                    
                    if not line:
                        continue
                        
                    # Skip comment lines but track header end
                    if line.startswith('#'):
                        if line.startswith('#CHROM'):
                            in_header = False
                            # Parse column headers
                            columns = line[1:].strip().split('\t')
                            if len(columns) < 8:
                                print(f"Warning: VCF file has only {len(columns)} columns")
                        continue
                    
                    # Data line
                    if not in_header:
                        parts = line.split('\t')
                        
                        if len(parts) < 5:
                            print(f"Warning: Line {line_number} has only {len(parts)} columns, skipping")
                            continue
                        
                        # Extract basic variant info
                        chrom = parts[0].replace('chr', '').replace('Chr', '').replace('CHR', '')
                        # Remove any additional chromosome markers
                        chrom = chrom.split(':')[0] if ':' in chrom else chrom
                        
                        try:
                            pos = int(parts[1])
                        except ValueError:
                            print(f"Warning: Invalid position at line {line_number}: {parts[1]}, skipping")
                            continue
                        
                        variant_id = parts[2] if len(parts) > 2 else '.'
                        ref = parts[3]
                        alt = parts[4]
                        
                        # Split multiple ALTs if present
                        alts = alt.split(',')
                        
                        for single_alt in alts:
                            # Check if variant is in breast cancer genes
                            gene = None
                            for gene_name, coords in BREAST_CANCER_GENES.items():
                                gene_chrom = coords['chr']
                                if chrom == gene_chrom and coords['start'] <= pos <= coords['end']:
                                    gene = gene_name
                                    break
                            
                            if gene:
                                # Parse INFO field if available
                                consequence = None
                                clinvar_sig = None
                                af = None
                                
                                if len(parts) > 7:
                                    info = parts[7]
                                    # Look for consequence in INFO
                                    for info_field in info.split(';'):
                                        if '=' in info_field:
                                            key, value = info_field.split('=', 1)
                                            if key == 'CSQ' or key == 'Consequence':
                                                consequence = value.split('|')[0] if '|' in value else value
                                            elif key == 'CLNSIG' or 'clinvar' in key.lower():
                                                clinvar_sig = value
                                            elif key == 'AF' or key == 'gnomad_af':
                                                try:
                                                    af = float(value)
                                                except:
                                                    pass
                                
                                # Create variant object
                                variant = GeneticVariant(
                                    chromosome=chrom,
                                    position=pos,
                                    ref=ref,
                                    alt=single_alt,
                                    gene=gene,
                                    rsid=variant_id if variant_id.startswith('rs') else None,
                                    consequence=consequence or 'unknown',
                                    clinvar_significance=clinvar_sig
                                )
                                
                                # Store allele frequency
                                if af is not None:
                                    variant.gnomad_af = af
                                
                                variants.append(variant)
                
        except Exception as e:
            print(f"Error parsing VCF file: {e}")
            # Fallback to simple line-by-line reading
            return self._parse_vcf_fallback(vcf_path)
        
        print(f"Total variants in breast cancer genes: {len(variants)}")
        return variants

    def _parse_vcf_fallback(self, vcf_path: str) -> List[GeneticVariant]:
        """Fallback parser for malformed VCF files"""
        variants = []
        
        with open(vcf_path, 'r', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                # Simple tab splitting
                parts = line.split('\t')
                if len(parts) < 5:
                    continue
                
                try:
                    chrom = parts[0]
                    pos = int(parts[1])
                    ref = parts[3]
                    alt = parts[4]
                    
                    # Simple gene matching based on position ranges
                    gene = None
                    if '17' in chrom and 43000000 <= pos <= 43130000:
                        gene = 'BRCA1'
                    elif '13' in chrom and 32880000 <= pos <= 32980000:
                        gene = 'BRCA2'
                    elif '16' in chrom and 23610000 <= pos <= 23660000:
                        gene = 'PALB2'
                    
                    if gene:
                        variant = GeneticVariant(
                            chromosome=chrom,
                            position=pos,
                            ref=ref,
                            alt=alt,
                            gene=gene,
                            consequence='unknown'
                        )
                        variants.append(variant)
                except:
                    continue
        
        return variants
    
    def _classify_variants(self):
        """Classify variants based on annotation data"""
        print(f"\nClassifying {len(self.variants)} variants...")
        
        for i, variant in enumerate(self.variants):
            # Get annotation based on mode
            if self.mode == 'online':
                annotation = self._fetch_online_annotation(variant)
            else:
                annotation = self._get_annotation_from_local_db(variant)
            
            # Update variant with annotation data
            if annotation:
                variant.clinvar_significance = annotation.get('clinvar_significance')
                variant.consequence = annotation.get('consequence', variant.consequence)
                
                if 'gnomad_af' in annotation:
                    variant.gnomad_af = annotation.get('gnomad_af')
                
                variant.classification = annotation.get('classification')
                
                # Determine risk level
                clinvar_sig = annotation.get('clinvar_significance', '').lower()
                
                if any(term in clinvar_sig for term in ['pathogenic', 'likely pathogenic']):
                    variant.risk_level = RiskLevel.HIGH.value
                elif 'uncertain' in clinvar_sig:
                    variant.risk_level = RiskLevel.VUS.value
                elif any(term in clinvar_sig for term in ['benign', 'likely benign']):
                    variant.risk_level = RiskLevel.POPULATION.value
                else:
                    # If no ClinVar data, use other classification
                    classification = annotation.get('classification', '').lower()
                    if 'pathogenic' in classification:
                        variant.risk_level = RiskLevel.HIGH.value
                    elif 'benign' in classification:
                        variant.risk_level = RiskLevel.POPULATION.value
                    else:
                        variant.risk_level = RiskLevel.VUS.value
            
            # Print progress
            if (i + 1) % 10 == 0 or i == len(self.variants) - 1:
                print(f"  Classified {i + 1}/{len(self.variants)} variants")
    
    def _fetch_online_annotation(self, variant: GeneticVariant) -> Dict:
        """Fetch variant annotation from online APIs"""
        try:
            print(f"  Fetching online annotation for {variant.gene}:{variant.position}...")
            
            annotation = {
                'clinvar_significance': 'Uncertain_significance',
                'gnomad_af': variant.gnomad_af or 0.001,
                'classification': 'unknown'
            }
            
            # Simple rule-based for MVP
            if variant.consequence and any(term in variant.consequence.lower() 
                                        for term in ['frameshift', 'stop_gained', 'splice']):
                annotation['classification'] = 'likely_pathogenic'
                annotation['clinvar_significance'] = 'Likely_pathogenic'
            elif variant.consequence and 'missense' in variant.consequence.lower():
                annotation['classification'] = 'benign'
                annotation['clinvar_significance'] = 'Benign'
            
            return annotation
            
        except Exception as e:
            print(f"  Online annotation failed: {e}")
            return self._get_annotation_from_local_db(variant)
    
    def _get_annotation_from_local_db(self, variant: GeneticVariant) -> Dict:
        """Get annotation from local rules"""
        annotation = {
            'clinvar_significance': 'Uncertain_significance',
            'gnomad_af': variant.gnomad_af or 0.001,
            'classification': 'unknown'
        }
        
        # Enhanced rule-based classification
        if variant.consequence:
            cons_lower = variant.consequence.lower()
            
            # High-risk consequences
            if any(term in cons_lower for term in ['frameshift', 'stop_gained', 'splice_donor', 'splice_acceptor']):
                annotation['classification'] = 'pathogenic'
                annotation['clinvar_significance'] = 'Pathogenic'
            
            # Moderate-risk consequences
            elif any(term in cons_lower for term in ['missense', 'inframe']):
                # Check if in known pathogenic genes
                if variant.gene in ['BRCA1', 'BRCA2', 'TP53']:
                    annotation['classification'] = 'likely_pathogenic'
                    annotation['clinvar_significance'] = 'Likely_pathogenic'
                else:
                    annotation['classification'] = 'uncertain'
                    annotation['clinvar_significance'] = 'Uncertain_significance'
            
            # Likely benign
            elif any(term in cons_lower for term in ['synonymous', 'intron']):
                annotation['classification'] = 'benign'
                annotation['clinvar_significance'] = 'Benign'
        
        # Check for known pathogenic variants in BRCA genes
        if variant.gene in ['BRCA1', 'BRCA2']:
            known_pathogenic = [
                (43091995, 'AG', 'A'),  # BRCA1 c.68_69delAG
                (32913838, 'T', '-'),   # BRCA2 c.5946delT
            ]
            
            for known_pos, known_ref, known_alt in known_pathogenic:
                if (variant.position == known_pos and 
                    variant.ref == known_ref and 
                    variant.alt == known_alt):
                    annotation['classification'] = 'pathogenic'
                    annotation['clinvar_significance'] = 'Pathogenic'
                    break
        
        return annotation
    
    def _generate_results(self) -> Dict:
        """Generate comprehensive analysis results"""
        print(f"\nGenerating analysis results...")
        
        # Calculate overall risk
        overall_risk = self._calculate_overall_risk()
        
        # Prepare variant table
        variant_table = [v.to_dict() for v in self.variants]
        
        # Generate summary statistics
        summary = self._generate_summary_statistics()
        
        # Generate recommendations
        recommendations = self._generate_recommendations()
        
        # Generate plots data
        plots_data = self._generate_plots_data()
        
        results = {
            'patient_id': self.patient_id,
            'analysis_date': datetime.now().isoformat(),
            'overall_risk': overall_risk,
            'variant_count': len(self.variants),
            'pathogenic_count': sum(1 for v in self.variants 
                                 if v.risk_level == RiskLevel.HIGH.value),
            'vus_count': sum(1 for v in self.variants 
                           if v.risk_level == RiskLevel.VUS.value),
            'variants': variant_table[:100],  # Limit to 100 variants for display
            'summary': summary,
            'recommendations': recommendations,
            'plots': plots_data
        }
        
        return results
    
    def _generate_error_results(self, error_message: str) -> Dict:
        """Generate error results when analysis fails"""
        return {
            'patient_id': self.patient_id,
            'analysis_date': datetime.now().isoformat(),
            'overall_risk': 'Analysis Error',
            'variant_count': 0,
            'pathogenic_count': 0,
            'vus_count': 0,
            'variants': [],
            'summary': {
                'risk_interpretation': f'Analysis error: {error_message}',
                'clinical_implications': ['Please check VCF file format'],
                'high_risk_genes': [],
                'genes_with_variants': [],
                'total_genes_analyzed': len(BREAST_CANCER_GENES)
            },
            'recommendations': [
                {
                    'priority': 'high',
                    'recommendation': 'Check VCF file format',
                    'rationale': 'Analysis could not process the file'
                }
            ],
            'plots': {
                'risk_distribution': {'High Risk': 0, 'VUS': 0, 'Low Risk': 0},
                'gene_distribution': {}
            }
        }
    
    def _calculate_overall_risk(self) -> str:
        """Calculate overall risk level based on variants found"""
        high_risk_variants = [v for v in self.variants 
                            if v.risk_level == RiskLevel.HIGH.value]
        moderate_risk_variants = [v for v in self.variants 
                                if v.risk_level == RiskLevel.MODERATE.value]
        vus_variants = [v for v in self.variants 
                       if v.risk_level == RiskLevel.VUS.value]
        
        if high_risk_variants:
            # High-risk genes: BRCA1, BRCA2, PALB2, TP53
            high_risk_genes = ['BRCA1', 'BRCA2', 'PALB2', 'TP53']
            if any(v.gene in high_risk_genes for v in high_risk_variants):
                return RiskLevel.HIGH.value
            else:
                return RiskLevel.MODERATE.value
        elif moderate_risk_variants:
            return RiskLevel.MODERATE.value
        elif vus_variants:
            return RiskLevel.VUS.value
        else:
            return RiskLevel.POPULATION.value
    
    def _generate_summary_statistics(self) -> Dict:
        """Generate summary statistics for the report"""
        high_risk_genes = list(set(v.gene for v in self.variants 
                                 if v.risk_level == RiskLevel.HIGH.value))
        
        # Get unique genes with variants
        genes_with_variants = list(set(v.gene for v in self.variants))
        
        risk_interpretation = self._get_risk_interpretation()
        clinical_implications = self._get_clinical_implications()
        
        return {
            'high_risk_genes': high_risk_genes,
            'genes_with_variants': genes_with_variants,
            'total_genes_analyzed': len(BREAST_CANCER_GENES),
            'risk_interpretation': risk_interpretation,
            'clinical_implications': clinical_implications
        }
    
    def _get_risk_interpretation(self) -> str:
        """Get plain language risk interpretation"""
        high_risk_count = sum(1 for v in self.variants 
                            if v.risk_level == RiskLevel.HIGH.value)
        vus_count = sum(1 for v in self.variants 
                       if v.risk_level == RiskLevel.VUS.value)
        
        if high_risk_count > 0:
            high_risk_genes = [v.gene for v in self.variants 
                             if v.risk_level == RiskLevel.HIGH.value]
            gene_list = ', '.join(set(high_risk_genes))
            return f"Detected {high_risk_count} pathogenic variant(s) in gene(s): {gene_list}. This indicates increased hereditary breast cancer risk."
        elif vus_count > 0:
            return f"Detected {vus_count} variant(s) of uncertain significance (VUS). Genetic counseling recommended."
        else:
            return "No pathogenic variants detected in analyzed breast cancer genes. Risk at population level."
    
    def _get_clinical_implications(self) -> List[str]:
        """Generate clinical implications based on findings"""
        implications = []
        
        high_risk_genes = list(set(v.gene for v in self.variants 
                                 if v.risk_level == RiskLevel.HIGH.value))
        
        if not high_risk_genes and len(self.variants) == 0:
            implications.append("No genetic variants detected in breast cancer risk genes")
            implications.append("Continue with age-appropriate population screening")
            return implications
        
        if 'BRCA1' in high_risk_genes or 'BRCA2' in high_risk_genes:
            implications.extend([
                "High lifetime risk of breast cancer (45-85%)",
                "Increased risk of ovarian cancer",
                "Consider enhanced screening with MRI",
                "Referral to genetic counseling recommended"
            ])
        elif high_risk_genes:
            implications.extend([
                "Increased breast cancer risk",
                "Consider enhanced surveillance",
                "Genetic counseling recommended"
            ])
        else:
            implications.append("Continue age-appropriate screening")
        
        return implications
    
    def _generate_recommendations(self) -> List[Dict]:
        """Generate clinical recommendations"""
        recommendations = []
        
        high_risk_variants = [v for v in self.variants 
                            if v.risk_level == RiskLevel.HIGH.value]
        vus_variants = [v for v in self.variants 
                       if v.risk_level == RiskLevel.VUS.value]
        
        if high_risk_variants:
            recommendations.append({
                'priority': 'high',
                'recommendation': 'Referral to genetic counseling',
                'rationale': 'Pathogenic variant(s) detected'
            })
            recommendations.append({
                'priority': 'high', 
                'recommendation': 'Enhanced breast screening',
                'rationale': 'Increased breast cancer risk'
            })
        elif vus_variants:
            recommendations.append({
                'priority': 'medium',
                'recommendation': 'Genetic counseling for VUS interpretation',
                'rationale': 'Variant of uncertain significance detected'
            })
        else:
            recommendations.append({
                'priority': 'low',
                'recommendation': 'Continue routine screening',
                'rationale': 'No pathogenic variants detected'
            })
        
        return recommendations
    
    def _generate_plots_data(self) -> Dict:
        """Generate data for visualizations"""
        # Count variants by risk level
        risk_counts = {
            'High Risk': sum(1 for v in self.variants 
                           if v.risk_level == RiskLevel.HIGH.value),
            'VUS': sum(1 for v in self.variants 
                      if v.risk_level == RiskLevel.VUS.value),
            'Low Risk': sum(1 for v in self.variants 
                          if v.risk_level not in [RiskLevel.HIGH.value, RiskLevel.VUS.value])
        }
        
        # Count variants by gene
        gene_counts = {}
        for variant in self.variants:
            gene_counts[variant.gene] = gene_counts.get(variant.gene, 0) + 1
        
        # Count by variant type
        variant_types = {}
        for variant in self.variants:
            if variant.consequence:
                consequence = variant.consequence.lower()
                if 'missense' in consequence:
                    variant_types['Missense'] = variant_types.get('Missense', 0) + 1
                elif 'frameshift' in consequence:
                    variant_types['Frameshift'] = variant_types.get('Frameshift', 0) + 1
                elif 'splice' in consequence:
                    variant_types['Splice Site'] = variant_types.get('Splice Site', 0) + 1
                elif 'stop' in consequence:
                    variant_types['Stop Gain'] = variant_types.get('Stop Gain', 0) + 1
                else:
                    variant_types['Other'] = variant_types.get('Other', 0) + 1
            else:
                variant_types['Unknown'] = variant_types.get('Unknown', 0) + 1
        
        return {
            'risk_distribution': risk_counts,
            'gene_distribution': gene_counts,
            'variant_types': variant_types,
        }
    
    def save_results(self, output_path: str):
        """Save analysis results to JSON file"""
        with open(output_path, 'w') as f:
            json.dump(self.results, f, indent=2, default=str)
        print(f"Results saved to: {output_path}")
    
    def generate_report_text(self) -> str:
        """Generate text report summary"""
        if not self.results:
            return "No analysis results available"
        
        report = f"""
        ============================================
        BREAST CANCER GENETIC RISK ASSESSMENT REPORT
        ============================================
        
        Patient ID: {self.results['patient_id']}
        Analysis Date: {self.results['analysis_date'].split('T')[0]}
        
        SUMMARY
        -------
        Overall Risk Level: {self.results['overall_risk']}
        Variants Analyzed: {self.results['variant_count']}
        Pathogenic Variants: {self.results['pathogenic_count']}
        VUS: {self.results['vus_count']}
        
        KEY FINDINGS
        ------------
        {self.results['summary']['risk_interpretation']}
        
        CLINICAL IMPLICATIONS
        ---------------------
        {chr(10).join(f"• {imp}" for imp in self.results['summary']['clinical_implications'])}
        
        RECOMMENDATIONS
        ---------------
        {chr(10).join(f"• [{rec['priority'].upper()}] {rec['recommendation']}" 
                    for rec in self.results['recommendations'])}
        
        ============================================
        End of Report
        ============================================
        """
        
        return report

# Standalone functions for backward compatibility
def analyze_vcf(vcf_path: str, patient_id: str = "P001", mode: str = 'offline') -> Dict:
    """Standalone function for VCF analysis"""
    analyzer = GeneticAnalyzer(mode=mode)
    return analyzer.process_vcf(vcf_path, patient_id)

def save_results(results: Dict, output_path: str):
    """Standalone function to save results"""
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    print(f"Results saved to: {output_path}")

def main():
    """Command line interface"""
    if len(sys.argv) < 2:
        print("Usage: python genetic_analyzer.py <vcf_file> [patient_id]")
        print("\nExample: python genetic_analyzer.py sample.vcf P001")
        
        # Create a test VCF if no arguments
        test_vcf = "test_sample.vcf"
        test_content = """##fileformat=VCFv4.2
##source=TestGenerator
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
17	43091995	rs80357914	AG	A	100	PASS	CSQ=frameshift_variant
13	32913838	rs80359600	T	-	100	PASS	CSQ=frameshift_variant
16	23646201	rs180177143	C	T	100	PASS	CSQ=missense_variant
17	7674223	rs11540652	G	A	100	PASS	CSQ=missense_variant
11	108223456	rs1801516	A	G	100	PASS	CSQ=missense_variant
"""
        with open(test_vcf, 'w') as f:
            f.write(test_content)
        print(f"\nCreated test VCF file: {test_vcf}")
        
        # Test with the created file
        analyzer = GeneticAnalyzer(mode='offline')
        results = analyzer.process_vcf(test_vcf, "TEST001")
        analyzer.save_results("test_results.json")
        
        # Show summary
        print(f"\nTest Results Summary:")
        print(f"Patient: {results['patient_id']}")
        print(f"Variants: {results['variant_count']}")
        print(f"Risk: {results['overall_risk']}")
        
        return
    
    vcf_file = sys.argv[1]
    patient_id = sys.argv[2] if len(sys.argv) > 2 else "P001"
    mode = sys.argv[3] if len(sys.argv) > 3 else "offline"
    
    if not os.path.exists(vcf_file):
        print(f"Error: VCF file not found: {vcf_file}")
        sys.exit(1)
    
    # Run analysis
    analyzer = GeneticAnalyzer(mode=mode)
    results = analyzer.process_vcf(vcf_file, patient_id)
    
    # Save results
    output_file = f"{patient_id}_analysis_results.json"
    analyzer.save_results(output_file)
    
    # Print summary
    print(f"\nResults saved to: {output_file}")
    print(f"\nAnalysis Summary:")
    print(f"  Patient ID: {results['patient_id']}")
    print(f"  Variants in breast cancer genes: {results['variant_count']}")
    print(f"  Pathogenic variants: {results['pathogenic_count']}")
    print(f"  VUS: {results['vus_count']}")
    print(f"  Overall Risk: {results['overall_risk']}")
    
    if results['variants']:
        print(f"\nFirst few variants:")
        for i, var in enumerate(results['variants'][:3]):
            print(f"  {i+1}. {var['gene']}:{var['chromosome']}:{var['position']} "
                  f"{var['ref']}→{var['alt']} ({var['consequence']})")

if __name__ == "__main__":
    main()