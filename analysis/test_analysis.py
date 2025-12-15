#!/usr/bin/env python3
"""
Quick test script to verify VCF analysis works
"""

import sys
import os
from genetic_analyzer import GeneticAnalyzer

def main():
    # Test with provided VCF or sample
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        vcf_file = sys.argv[1]
    else:
        # Create sample VCF
        vcf_file = "test_sample.vcf"
        sample_vcf = """##fileformat=VCFv4.2
##source=TestGenerator
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
17	43091995	rs80357914	AG	A	100	PASS	CSQ=frameshift_variant
13	32913838	rs80359600	T	-	100	PASS	CSQ=frameshift_variant
16	23646201	rs180177143	C	T	100	PASS	CSQ=missense_variant
"""
        with open(vcf_file, 'w') as f:
            f.write(sample_vcf)
        print(f"Created test VCF file: {vcf_file}")
    
    print(f"Testing analysis with: {vcf_file}")
    
    # Run analysis
    analyzer = GeneticAnalyzer(mode='offline')
    results = analyzer.process_vcf(vcf_file, "TEST001")
    
    print("\n" + "="*60)
    print("ANALYSIS RESULTS:")
    print("="*60)
    print(f"Patient ID: {results['patient_id']}")
    print(f"Variants found: {results['variant_count']}")
    print(f"Pathogenic: {results['pathogenic_count']}")
    print(f"VUS: {results['vus_count']}")
    print(f"Overall risk: {results['overall_risk']}")
    
    if results['variants']:
        print("\nDetected variants:")
        for i, variant in enumerate(results['variants'][:5]):
            print(f"  {i+1}. {variant['gene']}: {variant['chromosome']}:{variant['position']} "
                  f"{variant['ref']}→{variant['alt']} ({variant['consequence']}) - {variant['risk_level']}")
    
    print("\n" + "="*60)
    print("If you see variants above, the analysis is working!")
    print("If not, check your VCF file format.")
    print("="*60)

if __name__ == "__main__":
    main()