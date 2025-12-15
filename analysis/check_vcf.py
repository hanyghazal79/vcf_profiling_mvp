# check_vcf.py
import sys

def check_vcf_file(vcf_path):
    print(f"Checking VCF file: {vcf_path}")
    
    with open(vcf_path, 'r') as f:
        lines = []
        for i, line in enumerate(f):
            lines.append(line.strip())
            if i >= 20:  # Check first 20 lines
                break
    
    print(f"Total lines read: {len(lines)}")
    print("\nFirst 10 lines:")
    for i, line in enumerate(lines[:10]):
        print(f"{i+1}: {line}")
    
    # Check for #CHROM
    has_chrom = any('#CHROM' in line for line in lines)
    print(f"\nContains #CHROM header: {has_chrom}")
    
    # Check file format
    has_format = any('fileformat' in line.lower() for line in lines)
    print(f"Contains fileformat: {has_format}")
    
    # Count data lines
    data_lines = [l for l in lines if not l.startswith('#') and l.strip()]
    print(f"Data lines (non-comment): {len(data_lines)}")
    
    if data_lines:
        print("\nFirst data line:")
        print(data_lines[0])
        
        # Parse data line
        parts = data_lines[0].split('\t')
        print(f"Columns in data line: {len(parts)}")
        if len(parts) >= 8:
            print(f"CHROM: {parts[0]}")
            print(f"POS: {parts[1]}")
            print(f"ID: {parts[2]}")
            print(f"REF: {parts[3]}")
            print(f"ALT: {parts[4]}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        check_vcf_file(sys.argv[1])
    else:
        print("Usage: python check_vcf.py <vcf_file>")