import argparse
import csv
import os

def main():
    parser = argparse.ArgumentParser(description = "Analyze CSV file")
    parser.add_argument('file', help = 'File to analyze')
    parser.add_argument('table', help = 'Table to create')
    
    args = parser.parse_args()

    args.file = os.path.expanduser(args.file)
    path, filename = os.path.split(args.file)
    filename = os.path.splitext(filename)[0]
    outFileName = '%s-SCRIPT.sql' % filename
    outFileName = os.path.join(path, outFileName)

    inFileName = '%s-DESC.csv' % filename
    inFileName = os.path.join(path, inFileName)

    fileIn = open(inFileName)
    csvIn = csv.reader(fileIn)

    h = next(csvIn)

    dictionary = list()
    for i in csvIn:
        dictionary.append(dict(zip(h, [j.strip() for j in i])))

    fileIn.close()


    fileOut = open(outFileName, 'wt')

    fileOut.write('drop table %s;\n' % args.table)

    fileOut.write('create table %s (\n' % args.table)

    fileOut.write(',\n'.join(['\t' + i['Database Name'] + ' ' +
                          ('varchar(%s)' % max(1, int(i['Max Length'])))
                   for i in dictionary]))
    fileOut.write(');\n\n')

    # Load
    fileOut.write('copy ' + args.table + " from '" +
                  os.path.abspath(args.file) +
                  "' csv header;\n\n");

    
    for i in dictionary:
        # Drop tables
        if i['Drop'] == '1' or i['Drop'].lower() == 'true':
            fileOut.write('alter table ' + args.table + ' alter column ' +
                          i['Database Name'] + ' drop default;\n')
        # Alter Columns
        elif i['Type'].lower() == 'numeric':
            fileOut.write('alter table ' + args.table + ' alter column ' +
                          i['Database Name'] + ' set data type numeric using ' +
                          i['Database Name'])
            if len(i['Format'].strip()) == 0:
                fileOut.write('::numeric;\n')
            else:
                fileOut.write('::numeric(' + i['Format'].strip() + ');\n')
        elif i['Type'].lower() == 'date':
            fileOut.write('alter table ' + args.table + ' alter column ' +
                          i['Database Name'] +
                          ' set data type date using to_date(' +
                          i['Database Name'] + ", '" + i['Format'] + "');\n")

        # Column Descriptions
        if len(i['Description'].strip()) > 0:
            fileOut.write('comment on column ' + args.table + '.' +
                          i['Database Name'] + " is '" +
                          i['Description'].strip() + "';")


    fileOut.close()

if __name__ == "__main__":
    main()


    
