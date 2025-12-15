"""
FastAPI server for Breast Cancer Genetic Risk Analysis
Handles real VCF analysis with cyvcf2
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from typing import Optional, List, Dict
import uvicorn
import json
import tempfile
import os
from pathlib import Path
import shutil
import uuid
from datetime import datetime
import asyncio
from concurrent.futures import ThreadPoolExecutor

from genetic_analyzer import GeneticAnalyzer

app = FastAPI(
    title="Breast Cancer Genetic Risk API",
    description="API for analyzing VCF files for breast cancer risk variants using real VCF analysis",
    version="2.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your Flutter app domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for analysis jobs (in production, use Redis or database)
analysis_jobs: Dict[str, Dict] = {}
executor = ThreadPoolExecutor(max_workers=4)

@app.get("/")
async def root():
    return {"message": "Breast Cancer Genetic Risk Assessment API v2.0", "status": "operational"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "breast-cancer-genetic-risk-api",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/genes")
async def get_analyzed_genes():
    """Get list of breast cancer genes analyzed"""
    from genetic_analyzer import BREAST_CANCER_GENES
    return {
        "genes": list(BREAST_CANCER_GENES.keys()),
        "count": len(BREAST_CANCER_GENES),
        "description": "Hereditary breast cancer risk genes analyzed"
    }

@app.post("/api/analyze")
async def analyze_vcf(
    file: UploadFile = File(...),
    patient_id: Optional[str] = Query("P001", description="Patient identifier"),
    mode: Optional[str] = Query("offline", description="Analysis mode: offline or online"),
    background_tasks: BackgroundTasks = None
):
    """
    Analyze VCF file for breast cancer risk variants
    
    Args:
        file: VCF file upload (.vcf or .vcf.gz)
        patient_id: Patient identifier
        mode: Analysis mode - 'offline' (local rules) or 'online' (API calls)
    
    Returns:
        Analysis job ID for status tracking
    """
    try:
        # Validate file type
        if not file.filename.endswith(('.vcf', '.vcf.gz')):
            raise HTTPException(
                status_code=400, 
                detail="File must be a VCF file (.vcf or .vcf.gz)"
            )
        
        # Generate unique job ID
        job_id = str(uuid.uuid4())
        
        # Save uploaded file to temporary location
        temp_dir = tempfile.mkdtemp(prefix="vcf_analysis_")
        vcf_path = os.path.join(temp_dir, file.filename)
        
        # Save uploaded content
        content = await file.read()
        with open(vcf_path, 'wb') as f:
            f.write(content)
        
        # Validate minimum VCF content
        with open(vcf_path, 'r') as f:
            vcf_content = f.read(1000)  # Read first 1000 chars
            if "#CHROM" not in vcf_content:
                raise HTTPException(status_code=400, detail="Invalid VCF file format")
        
        # Initialize job status
        analysis_jobs[job_id] = {
            "status": "processing",
            "patient_id": patient_id,
            "filename": file.filename,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "temp_dir": temp_dir,
            "vcf_path": vcf_path,
            "mode": mode,
            "results": None,
            "error": None
        }
        
        # Start analysis in background
        if background_tasks:
            background_tasks.add_task(
                process_vcf_background,
                job_id,
                vcf_path,
                patient_id,
                mode,
                temp_dir
            )
        else:
            # Process synchronously for simple requests
            executor.submit(
                process_vcf_background,
                job_id,
                vcf_path,
                patient_id,
                mode,
                temp_dir
            )
        
        return {
            "job_id": job_id,
            "status": "processing",
            "message": f"Analysis started for {file.filename}",
            "patient_id": patient_id,
            "created_at": analysis_jobs[job_id]["created_at"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis setup failed: {str(e)}")

def process_vcf_background(job_id: str, vcf_path: str, patient_id: str, mode: str, temp_dir: str):
    """Process VCF file in background thread"""
    try:
        if job_id not in analysis_jobs:
            return
        
        analysis_jobs[job_id]["status"] = "processing"
        analysis_jobs[job_id]["updated_at"] = datetime.now().isoformat()
        
        # Perform analysis
        analyzer = GeneticAnalyzer(mode=mode)
        results = analyzer.process_vcf(vcf_path, patient_id)
        
        # Save results to file
        results_file = os.path.join(temp_dir, f"results_{job_id}.json")
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        # Update job status
        analysis_jobs[job_id]["status"] = "completed"
        analysis_jobs[job_id]["results"] = results
        analysis_jobs[job_id]["results_file"] = results_file
        analysis_jobs[job_id]["updated_at"] = datetime.now().isoformat()
        
        # Generate report
        report_file = generate_report(results, temp_dir, job_id)
        if report_file:
            analysis_jobs[job_id]["report_file"] = report_file
        
    except Exception as e:
        error_msg = f"Analysis failed: {str(e)}"
        print(f"Error in job {job_id}: {error_msg}")
        
        if job_id in analysis_jobs:
            analysis_jobs[job_id]["status"] = "failed"
            analysis_jobs[job_id]["error"] = error_msg
            analysis_jobs[job_id]["updated_at"] = datetime.now().isoformat()
        
        # Cleanup temp dir on error
        try:
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir, ignore_errors=True)
        except:
            pass

@app.get("/api/analysis/{job_id}")
async def get_analysis_results(job_id: str):
    """Get analysis results by job ID"""
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = analysis_jobs[job_id]
    
    if job["status"] == "processing":
        return {
            "job_id": job_id,
            "status": "processing",
            "message": "Analysis in progress",
            "patient_id": job["patient_id"],
            "created_at": job["created_at"],
            "updated_at": job["updated_at"]
        }
    
    elif job["status"] == "failed":
        return {
            "job_id": job_id,
            "status": "failed",
            "error": job["error"],
            "patient_id": job["patient_id"],
            "created_at": job["created_at"],
            "updated_at": job["updated_at"]
        }
    
    elif job["status"] == "completed" and job["results"] is not None:
        return JSONResponse(content=job["results"])
    
    else:
        raise HTTPException(status_code=500, detail="Analysis results not available")

@app.get("/api/analysis/{job_id}/report")
async def get_analysis_report(job_id: str):
    """Download analysis report PDF"""
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = analysis_jobs[job_id]
    
    if job["status"] != "completed":
        raise HTTPException(status_code=400, detail="Analysis not completed")
    
    if "report_file" not in job or not os.path.exists(job["report_file"]):
        # Generate report if not exists
        report_file = generate_report(job["results"], job["temp_dir"], job_id)
        if not report_file:
            raise HTTPException(status_code=500, detail="Report generation failed")
        job["report_file"] = report_file
    
    return FileResponse(
        job["report_file"],
        media_type='application/pdf',
        filename=f"breast_cancer_risk_report_{job['patient_id']}.pdf"
    )

@app.get("/api/analysis/{job_id}/status")
async def get_analysis_status(job_id: str):
    """Get analysis job status"""
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = analysis_jobs[job_id]
    
    return {
        "job_id": job_id,
        "status": job["status"],
        "patient_id": job["patient_id"],
        "filename": job["filename"],
        "created_at": job["created_at"],
        "updated_at": job["updated_at"],
        "mode": job["mode"],
        "error": job.get("error")
    }

@app.delete("/api/analysis/{job_id}")
async def delete_analysis(job_id: str):
    """Delete analysis job and clean up files"""
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = analysis_jobs[job_id]
    
    # Clean up temporary directory
    if "temp_dir" in job and os.path.exists(job["temp_dir"]):
        try:
            shutil.rmtree(job["temp_dir"], ignore_errors=True)
        except:
            pass
    
    # Remove job from memory
    del analysis_jobs[job_id]
    
    return {"status": "deleted", "job_id": job_id}

@app.post("/api/analyze-direct")
async def analyze_vcf_direct(
    file: UploadFile = File(...),
    patient_id: Optional[str] = Query("P001"),
    mode: Optional[str] = Query("offline")
):
    """
    Direct VCF analysis (synchronous, for small files)
    
    Note: For large VCF files, use /api/analyze with background processing
    """
    try:
        # Validate file
        if not file.filename.endswith(('.vcf', '.vcf.gz')):
            raise HTTPException(status_code=400, detail="File must be a VCF file")
        
        # Save to temp file
        with tempfile.NamedTemporaryFile(mode='wb', suffix='.vcf', delete=False) as f:
            content = await file.read()
            f.write(content)
            vcf_path = f.name
        
        try:
            # Analyze
            analyzer = GeneticAnalyzer(mode=mode)
            results = analyzer.process_vcf(vcf_path, patient_id)
            
            return JSONResponse(content=results)
            
        finally:
            # Cleanup
            if os.path.exists(vcf_path):
                os.unlink(vcf_path)
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.post("/api/analyze-test")
async def analyze_test_vcf():
    """Test endpoint with sample VCF data"""
    try:
        # Create test VCF content
        test_vcf_content = """##fileformat=VCFv4.2
##source=TestGenerator
##INFO=<ID=CSQ,Number=.,Type=String,Description="Consequence">
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
17\t43091995\trs80357914\tAG\tA\t100\tPASS\tCSQ=frameshift_variant
13\t32913838\trs80359600\tT\t-\t100\tPASS\tCSQ=frameshift_variant
16\t23646201\trs180177143\tC\tT\t100\tPASS\tCSQ=missense_variant
17\t7674223\trs11540652\tG\tA\t100\tPASS\tCSQ=missense_variant
11\t108223456\trs1801516\tA\tG\t100\tPASS\tCSQ=missense_variant
"""
        
        # Save to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.vcf', delete=False) as f:
            f.write(test_vcf_content)
            vcf_path = f.name
        
        try:
            # Analyze
            analyzer = GeneticAnalyzer(mode='offline')
            results = analyzer.process_vcf(vcf_path, "TEST001")
            
            # Add test flag
            results["_test_data"] = True
            results["_message"] = "Test analysis completed successfully"
            
            return JSONResponse(content=results)
            
        finally:
            # Cleanup
            if os.path.exists(vcf_path):
                os.unlink(vcf_path)
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Test analysis failed: {str(e)}")

def generate_report(results: Dict, output_dir: str, job_id: str) -> Optional[str]:
    """Generate PDF report from analysis results"""
    try:
        from report_generator import PDFReportGenerator
        
        report_file = os.path.join(output_dir, f"report_{job_id}.pdf")
        generator = PDFReportGenerator(results)
        generator.generate_pdf_report(report_file)
        
        return report_file if os.path.exists(report_file) else None
        
    except Exception as e:
        print(f"Report generation failed: {e}")
        return None

# Cleanup old jobs periodically
async def cleanup_old_jobs():
    """Background task to clean up old analysis jobs"""
    while True:
        await asyncio.sleep(3600)  # Run every hour
        
        current_time = datetime.now()
        jobs_to_delete = []
        
        for job_id, job in analysis_jobs.items():
            created_at = datetime.fromisoformat(job["created_at"])
            age_hours = (current_time - created_at).total_seconds() / 3600
            
            if age_hours > 24:  # Delete jobs older than 24 hours
                jobs_to_delete.append(job_id)
        
        for job_id in jobs_to_delete:
            if job_id in analysis_jobs:
                job = analysis_jobs[job_id]
                # Clean up temp files
                if "temp_dir" in job and os.path.exists(job["temp_dir"]):
                    try:
                        shutil.rmtree(job["temp_dir"], ignore_errors=True)
                    except:
                        pass
                # Remove from memory
                del analysis_jobs[job_id]
                print(f"Cleaned up old job: {job_id}")

@app.on_event("startup")
async def startup_event():
    """Start background tasks on application startup"""
    # Start cleanup task
    asyncio.create_task(cleanup_old_jobs())

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown"""
    # Cleanup all temp directories
    for job_id, job in analysis_jobs.items():
        if "temp_dir" in job and os.path.exists(job["temp_dir"]):
            try:
                shutil.rmtree(job["temp_dir"], ignore_errors=True)
            except:
                pass
    # Shutdown executor
    executor.shutdown(wait=True)

if __name__ == "__main__":
    # Run server
    uvicorn.run(
        "api_server:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )