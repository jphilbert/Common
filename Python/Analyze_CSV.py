import os
import csv
from datetime import datetime
import logging
import re



def coerceString(x, dateFormat = '%Y-%m-%d'):
    # Check if X is string?

    try:
        return(datetime.strptime(x, dateFormat))
    except ValueError:
        pass
    try:
        return(int(x))
    except ValueError:
        pass
    try:
        return(float(x))
    except ValueError:
        pass
    return(x)
    

def isBlank(x):
    return(len(x.strip()) == 0)

# def isBlank(x):
#     # Verify by alphanumeric
#     return(not re.match(r'\S+', x.strip()))

def isBlankLine(r):
    # Verify by alphanumeric
    return(len(filter(lambda(x): not isBlank(x), r)) < 1)




def AnalyzeCSV(fileName, nHeader, nRows = -1, dateFormat = '%Y-%m-%d'):
    completeSummary = {'rows': 0,
                       'blank rows': 0,
                       'skipped rows': nHeader,
                       'file name': fileName,
                       'fields': []}
    
    def analyzeRow(r, currentSummary = []):
        def analyzeItem(i):
            summary = {'length': len(i),
                       'trim length': len(i.strip()),
                       'type': str(type(coerceString(i, dateFormat)))}
            if isBlank(i):
                summary['type'] = 'BLANK'
            return(summary)

        for i in range(len(r)):
            if len(completeSummary['fields']) < i+1:
                completeSummary['fields'].append({
                    'max length': 0,
                    'min length': float('inf'),
                    'max trim length': 0,
                    'min trim length': float('inf'),
                    'nFloat': 0,
                    'nInt': 0,
                    'nString': 0,
                    'nDate': 0,
                    'nBlank': 0})
                
            thisSummary = analyzeItem(r[i])
            cSItem = completeSummary['fields'][i]
            if cSItem['max length'] < thisSummary['length']:
                cSItem['max length'] = thisSummary['length']
            if cSItem['min length'] > thisSummary['length']:
                cSItem['min length'] = thisSummary['length']
            if cSItem['max trim length'] < thisSummary['trim length']:
                cSItem['max trim length'] = thisSummary['trim length']
            if cSItem['min trim length'] > thisSummary['trim length']:
                cSItem['min trim length'] = thisSummary['trim length']
            if thisSummary['type'] == "<type 'float'>":
                cSItem['nFloat'] += 1
            if thisSummary['type'] == "<type 'int'>":
                cSItem['nInt'] += 1
            if thisSummary['type'] == "<type 'str'>":
                cSItem['nString'] += 1
            if thisSummary['type'] == "<type 'datetime.datetime'>":
                cSItem['nDate'] += 1    
            if thisSummary['type'] == "BLANK":
                cSItem['nBlank'] += 1    
        

    try:
        fileIn = open(fileName)
    except:
        logging.critical('Could not open file: %s', fileName)
    else:
        csvIn = csv.reader(fileIn)
        # Skip the header
        for i in range(nHeader):
            next(csvIn)

        if nRows > 0:
            for i in range(nRows):
                l = next(csvIn)
                if not isBlankLine(l):
                    analyzeRow(l)
                    completeSummary['rows'] += 1
                else:
                    completeSummary['blank rows'] += 1
        else:
            for i in csvIn:
                if not isBlankLine(i):
                    analyzeRow(i)
                    completeSummary['rows'] += 1
                else:
                    completeSummary['blank rows'] += 1

        fileIn.close()

    return(completeSummary)


