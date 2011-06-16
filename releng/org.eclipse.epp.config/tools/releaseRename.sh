#!/bin/bash

RELEASETRAIN=indigo
RELEASEDIRECTORY=/home/data/httpd/download.eclipse.org/technology/epp/downloads/release
TESTDIRECTORY=/shared/technology/epp/epp_build/${RELEASETRAIN}/download
CURRENTDIR=${PWD}


#############################################################################

if [ -z ${2} ]
then
  echo "ERROR: At least two parameters (build id and target version) are necessary. Stopping."
  echo "       Example: \"sh releaseRename.sh 20080117-0620 M5\""
  exit 1
fi
TESTBUILDID=${1}
TARGETVERSION=${2}

echo "Running the releaseRename script for ${RELEASETRAIN} with build ${TESTBUILDID} and version ${TARGETVERSION}"

SOURCEDIR=${TESTDIRECTORY}/${TESTBUILDID}
echo -n "Checking source directory: "
if [ ! -d ${SOURCEDIR} ]
then
  echo "failed"
  echo "ERROR: ${SOURCEDIR} does not exist. Stopping."
  exit 1
fi
echo "okay"

TARGETDIR=${RELEASEDIRECTORY}/${RELEASETRAIN}/${TARGETVERSION}
echo -n "Checking target directory: "
if [ -d ${TARGETDIR} ]
then
  echo "failed"
  echo "ERROR: ${TARGETDIR} does already exist. Stopping."
  exit 1
fi
echo "okay"

echo 1st: Create the release directory ${TARGETDIR}
mkdir ${TARGETDIR}

echo 2nd: Copy logfiles
cp -a ${SOURCEDIR}/*.log ${TARGETDIR}

echo 3rd: Copy XML config files: renamed feature.xml and package configuration files
cp -a ${SOURCEDIR}/*.xml ${TARGETDIR}

echo 4th: Copy and rename packages
cd ${SOURCEDIR}
for II in *eclipse*; do
  if [[ ! ( "${II}" =~ ".sha1" || "${II}" =~ ".md5" || "${II}" =~ "^eclipse_" ) ]]
  then
    NEWNAME=`echo ${II} | \
             cut -d "_" -f 2- | \
             sed 's/linux\.gtk\.x86\_64/linux-gtk-x86\_64/' | \
             sed 's/linux\.gtk\.x86\./linux\-gtk\./' | \
             sed 's/win32\.win32\.x86\./win32\./' | \
             sed 's/win32\.win32\.x86\_64\./win32\-x86\_64\./' | \
             sed 's/macosx\.cocoa\.x86\_64/macosx\-cocoa-x86\_64/' | \
             sed 's/macosx\.cocoa\.x86/macosx\-cocoa/' | \
             sed 's/macosx\.carbon\.ppc/macosx\-carbon/'`
    echo .. Copying ${II} to ${TARGETDIR}/${NEWNAME}
    rsync -av ${II} ${TARGETDIR}/${NEWNAME}
    if [ $? = "0" ]; then
      echo .... Successfully copied
    else
      echo Trying again...
      rsync -av --bwlimit=400 ${II} ${TARGETDIR}/${NEWNAME}
    fi
  fi
done

echo 5th: Adjust package names with incubating components
cd ${TARGETDIR}
# pattern to match: <product name="eclipse-linuxtools-indigo-RC5-incubation" /> -> "eclipse-linuxtools-indigo-RC5"
INCUBATION=`ls *.xml | grep -v feature | xargs grep "product name=\"eclipse.*incubation" | sed 's/^.*\(eclipse-.*\)-incubation.*/\1/'`
echo Found ${INCUBATION} in incubation
for II in ${INCUBATION}; do
  echo ".. Renaming ${II} incubating packages"
  for INCUBATIONPACKAGE in `ls *${II}* | grep -v "\.md5$" | grep -v "\.sha1$" | grep -v "incubation"`; do
    INCUBATIONPACKAGE_FILE=`echo ${INCUBATIONPACKAGE} | sed 's:\(.*\)\('${II}'\)\(.*\):\1\2-incubation\3:'`
    echo ".... Moving ${INCUBATIONPACKAGE} to ${INCUBATIONPACKAGE_FILE}"
    mv ${INCUBATIONPACKAGE} ${INCUBATIONPACKAGE_FILE}
  done
done


echo 6th: Re-calculate checksum files
cd ${TARGETDIR}
for II in eclipse*.zip eclipse*.tar.gz; do 
  echo .. $II
  md5sum $II >$II.md5
  sha1sum $II >$II.sha1
done

echo Moving to release directory ${TARGETDIR} done.
exit 0
