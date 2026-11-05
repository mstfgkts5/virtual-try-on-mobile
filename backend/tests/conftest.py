import os
import sys

# Testler backend/ içindeki modülleri doğrudan import eder (main, spin_frames, spin_jobs)
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
