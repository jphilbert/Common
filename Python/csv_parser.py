import argparse
import csv
import os

def main():
    parser = argparse.ArgumentParser(description = "Analyze CSV file")
    parser.add_argument('file', help = 'File to analyze')
    parser.add_argument('-header', help = 'Contains column header',
                        default = 1, type = int)
    parser.add_argument('-skip', help = 'Skips rows',
                        default = 0, type = int)
    args = parser.parse_args()

    args.file = os.path.expanduser(args.file)
    path, filename = os.path.split(args.file)
    filename = os.path.splitext(filename)[0]
    outFileName = '%s-DESC.csv' % filename
    outFileName = os.path.join(path, outFileName)

   
    fileIn = open(args.file)
    csvIn = csv.reader(fileIn)

    for i in range(args.skip):
        next(csvIn)

    dictionary = list()
    
    l = next(csvIn)
    dictionary = list()
    nRows = 1
    nBadRows = 0
    
    for i in range(len(l)):
        dictionary.append({'name': 'n/a',
                   'initialString': '',
                   'maxLength': 0,
                   'maxString': ''})

    if args.header == 1:
        for i in range(len(l)):
            dictionary[i-1]['name'] = l[i-1]
        l = next(csvIn)

      
    for i in range(len(dictionary)):
        dictionary[i-1]['initialString'] = l[i-1]
        dictionary[i-1]['maxLength'] = len(l[i-1])
        dictionary[i-1]['maxString'] = l[i-1]

        
    for i in csvIn:
        nRows += 1
        if len(i) != len(dictionary):
            nBadRows += 1 
        for j in range(len(dictionary)):
            if dictionary[j-1]['maxLength'] < len(i[j-1]):
                dictionary[j-1]['maxLength'] = len(i[j-1])
                dictionary[j-1]['maxString'] = i[j-1]
    fileIn.close()

    print('Rows: %s' % nRows)
    print('Bad Rows: %s' % nBadRows)

    fileOut = open(outFileName, 'wt')
    csvOut = csv.writer(fileOut)

    csvOut.writerow(('Column Name', 'First Value',
                     'Max Length', 'Max Value'))
    for i in dictionary:
        csvOut.writerow((i['name'], i['initialString'],
                         i['maxLength'], i['maxString']))
    fileOut.close()

if __name__ == "__main__":
    main()
