NASTRAN-95 (NASA/COSMIC)
========================

What is in this folder
----------------------
nastran95-windows-x64.zip    Ready-to-run Windows build. Most people only need this.
nastran95-linux-x64.zip      Ready-to-run Linux build.
nastran95-source-patch.zip   For people who want to BUILD Nastran95 themselves. Not needed to run it. See below.
NASTRAN-95-Build-Report.md   How these builds were made and tested.
readme.txt                   This file.


Running on Windows
------------------
1. Unpack nastran95-windows-x64.zip to a SHORT path without spaces, for example C:\ClassicalFEA\Nastran95
   (the install path must be about 33 characters or less, or Nastran95 cannot find its rf files).
2. Add the bin folder (C:\ClassicalFEA\Nastran95\bin) to PATH.
3. Run a job like other Nastrans, from any folder:

       nastran95 job.dat

nastran95.bat is in the bin folder of the zip. It needs no Python.
Output goes next to the input file: job.f06 (results), job.f04 (log), job.pch (punch),
and job.op2 when the deck calls the OUTPUT2 module.
More detail is in the README.md inside the zip.


What the "source patch" zip is for
----------------------------------
NASA's original NASTRAN-95 source does not work when compiled with a modern Fortran compiler (gfortran).
It compiles, but almost every real job stops with "USER FATAL MESSAGE 8020, SYNTAX ERROR".
(This is the unresolved crash reported as nasa/NASTRAN-95 issue #15.)

nastran95-source-patch.zip holds the small set of changes that fix this:

  makefile                One extra compiler flag so gfortran accepts the old-style hex constants in the code.
  xdcode.f                The real fix. This routine unpacks each line of the built-in solution sequences
                          (the rf files) one character at a time. With gfortran the old code lost every comma,
                          so the solution sequences were misread. The patched routine copies the characters
                          directly instead.
  nastran.py              The Python runner, fixed to work with Python 3 and on Windows.
  nastran95-fixes.patch   The same three changes as one patch file, for use with "git apply".
  README.md               Build instructions (Linux, and Windows cross-compiled from Linux).
  NASTRAN-95-Build-Report.md   The full story.

The Windows and Linux zips above were built WITH these fixes already applied.
You only need the source patch zip if you want to compile Nastran95 yourself from the NASA source.

