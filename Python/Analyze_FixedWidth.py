import struct

def AnalyzeFixedWidth(fileName, breaks, nHeader = 0,
                      nRows = -1, dateFormat = '%Y-%m-%d'):
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
                print(i)
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
        

    breaks = zip([None] + breaks, breaks + [None])

    def parse(string):
        return(tuple(string[i:j] for i,j in breaks))
    
    try:
        fileIn = open(fileName)
    except:
        logging.critical('Could not open file: %s', fileName)
    else:
        # Skip the header
        for i in range(nHeader):
            fileIn.readline()
           
        if nRows > 0:
            for i in range(nRows):
                l = fileIn.readline()
                l = parse(l)
                if not isBlankLine(l):
                    analyzeRow(l)
                    completeSummary['rows'] += 1
                else:
                    completeSummary['blank rows'] += 1
        else:
            for i in fileIn:
                i = parse(i)
                if not isBlankLine(i):
                    analyzeRow(i)
                    completeSummary['rows'] += 1
                else:
                    completeSummary['blank rows'] += 1

        fileIn.close()

        logging.info(formatSummary(completeSummary))

    return(completeSummary)




temp = AnalyzeFixedWidth('/users/jhilbert/data/icd-9/v32/CMS32_DESC_SHORT_DX.txt', [5], nHeader = 1)


temp = AnalyzeFile('/users/jhilbert/data/icd-9/v32/CMS32_DESC_SHORT_DX.txt',
                   AnalyzeFile.FileType.FixedWidth, breaks = [5])
# temp.nHeader = 1
temp.Analyze()
print temp
temp.SaveCSV('/users/jhilbert/data/icd-9/v32/summary.csv')
temp.SaveConfig('/users/jhilbert/data/icd-9/v32/config.ini')


temp = AnalyzeFile(config = '/users/jhilbert/data/icd-9/v32/config.ini')
print temp

temp.Analyze()
print temp

temp = AnalyzeFile('/users/jhilbert/data/pfs relative value files/rvu14a/pprrvu14_v1219.csv',
                   AnalyzeFile.FileType.CSV)
temp.nHeader = 10
temp.nFooter = 0
temp.Analyze()
print temp


def formatSummary(x):
    string = ''

    # Main 
    mainFields = ['file name',
                  'rows',
                  'skipped rows',
                  'blank rows']
    for i in mainFields:
            string += '{} {} \n'.format((i+':').rjust(20), x[i])
    string += '\n'

    # Fields
    n = 1
    for i in x['fields']:
        string += 'Field: {}\n'.format(n)
        string += '{} {} / {} \n'.format('Length Max/Min:'.rjust(30),
                                         i['max length'], i['min length'])
        string += '{} {} / {} \n'.format('Length (trim) Max/Min:'.rjust(30),
                                         i['max trim length'],
                                         i['min trim length'])
        string += '{} {} \n'.format('Strings:'.rjust(30), i['nString'])
        string += '{} {} \n'.format('Integers:'.rjust(30)   , i['nInt']) 
        string += '{} {} \n'.format('Floats:'.rjust(30) , i['nFloat'])
        string += '{} {} \n'.format('Dates:'.rjust(30)  , i['nDate'])
        string += '{} {} \n'.format('Blanks:'.rjust(30) , i['nBlank']) 
        string += '\n'
        n += 1
    return(string)
