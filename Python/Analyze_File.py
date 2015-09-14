import os
import csv
from datetime import datetime
import logging
import re
from enum import Enum
import ConfigParser
import json

class AnalyzeFile:
    def __init__(self, *args, **kwargs):
        if 'config' in kwargs:
            self.LoadConfig(kwargs['config'])
        elif len(args) == 2:    
            self.__init(args[0], args[1], **kwargs)
        else:
            logging.critical(
                    'Must supply FILE and TYPE or CONFIG FILE')
            
    def __init(self, fileName, fileType, **kwargs):
        self.fileName = fileName
        self.fileType = fileType
        self.nHeader = 0
        self.nFooter = 0
        self.dateFormat = '%Y-%m-%d'
        self.__rows = 0
        self.__blankRows = 0
        self.fields = []
        
        # Create fixed width parser
        if fileType == self.FileType.FixedWidth:               
            if 'widths' in kwargs:
                self.widths = kwargs['widths']
                widths = [abs(i) for i in kwargs['widths']]
                self.breaks = [sum(widths[:i+1]) \
                               for i in range(len(kwargs['widths']))]
            elif 'breaks' in kwargs:
                self.breaks = kwargs['breaks']
                self.widths = [i-j \
                               for i,j in zip(self.breaks[1:],
                                              self.breaks[:(len(
                                                  self.breaks)-1)])]
                self.widths = self.breaks[0:1] + self.widths
            else:
                logging.critical(
                    'Widths or breaks must be supplied for fixed width files')
            self.__parser = self.__makeParser()


    class FileType(Enum):
        CSV = 1
        FixedWidth = 2

        
    def __str__(self):
        string = ''

        # Main
        string += 'File Name: {}\n'.rjust(25).format(self.fileName)
        string += '  {}\n'.rjust(25).format(self.fileType)
        if self.fileType == self.FileType.FixedWidth:
            string += 'Width: {}\n'.rjust(25).format(self.widths)
            string += 'Breaks: {}\n'.rjust(25).format(self.breaks)
        string += '\n'
        
        string += 'Rows: {}\n'.rjust(25).format(self.__rows)
        string += 'Rows - Blank: {}\n'.rjust(25).format(self.__blankRows)
        string += 'Rows - Headers: {}\n'.rjust(25).format(self.nHeader)
        string += 'Rows - Footers: {}\n'.rjust(25).format(self.nFooter)
        string += '\n'

        # Fields
        n = 1
        for i in self.fields:
            string += 'Field: {}\n'.rjust(25).format(n)
            string += 'Length Max/Min: {} / {}\n'.\
                      rjust(45).format(i['max length'], i['min length'])
            string += 'Length (trim) Max/Min: {} / {}\n'.\
                      rjust(45).format(i['max trim length'],
                                       i['min trim length'])
            string += 'Strings: {}\n'.rjust(40).format(i['nString'])
            string += 'Integers: {}\n'.rjust(40).format(i['nInt']) 
            string += 'Floats: {}\n'.rjust(40).format(i['nFloat'])
            string += 'Dates: {}\n'.rjust(40).format(i['nDate'])
            string += 'Blanks: {}\n'.rjust(40).format(i['nBlank']) 
            string += '\n'
            n += 1
        return(string)


    def __makeParser(self):
        breaks = zip([None] + self.breaks, self.breaks + [None])       
        def parse(string):
            return(tuple(string[i:j] for i,j in breaks))
        return(parse)

    
    def __coerceString(self, x):
        # Check if X is string?
        try:
            return(datetime.strptime(x, self.dateFormat))
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


    def __isBlank(self, x):
        return(len(x.strip()) == 0)
    

    def __isBlankLine(self, r):
        # Verify by alphanumeric
        return(len(filter(lambda(x): not self.__isBlank(x), r)) < 1)

    
    def __analyzeItem(self, i):
        summary = {'length': len(i),
                   'trim length': len(i.strip()),
                   'type': str(type(self.__coerceString(i)))}
        if self.__isBlank(i):
            summary['type'] = 'BLANK'
        
        return(summary)
    

    def __analyzeRow(self, r):
        for i in range(len(r)):
            if len(self.fields) < i+1:
                self.fields.append({
                    'max length': 0,
                    'min length': float('inf'),
                    'max trim length': 0,
                    'min trim length': float('inf'),
                    'nFloat': 0,
                    'nInt': 0,
                    'nString': 0,
                    'nDate': 0,
                    'nBlank': 0})
                
            thisSummary = self.__analyzeItem(r[i])
            cSItem = self.fields[i]
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


    def SaveCSV(self, fileName):
        oFile = open(fileName, 'wb')
        output = csv.writer(oFile)

        # Main
        output.writerow(['File Name', self.fileName])
        output.writerow(['File Type', self.fileType])
        if self.fileType == self.FileType.FixedWidth:
            output.writerow(['Width', self.widths])
            output.writerow(['Breaks', self.breaks])
        
        output.writerow(['Rows', self.__rows])
        output.writerow(['Rows - Blank', self.__blankRows])
        output.writerow(['Rows - Headers', self.nHeader])
        output.writerow(['Rows - Footers', self.nFooter])
        output.writerow([])

        # Fields
        # headers = self.fields[0].keys()
        # headers.sort()
        # output.writerow(headers)
        # for i in self.fields:
        #     output.writerow([i[j] for j in headers])


        headers = self.fields[0].keys()
        headers.sort()
        output = csv.DictWriter(oFile, fieldnames = headers)
        output.writeheader()
        for i in self.fields:
            output.writerow(i)
            
        oFile.close()


    def LoadConfig(self, fileName):
        Config = ConfigParser.ConfigParser()
        Config.read(fileName)

        # Main
        self.fileName = Config.get('Main', 'File Name')
        
        if Config.get('Main', 'File Type') == 'Fixed Width':
            self.fileType = self.FileType.FixedWidth
            self.breaks = json.loads(Config.get('Main', 'Breaks'))
            self.widths = [i-j \
                           for i,j in zip(self.breaks[1:],
                                          self.breaks[:(len(self.breaks)-1)])]
            self.widths = self.breaks[0:1] + self.widths
            self.__parser = self.__makeParser()
        else:
            self.fileType = self.FileType.CSV
            
        self.__rows = Config.getint('Main', 'Rows')
        self.nHeader = Config.getint('Main', 'Rows - Headers')
        self.nFooter = Config.getint('Main', 'Rows - Footers')
        self.dateFormat = '%Y-%m-%d'
        self.__blankRows = 0
        self.fields = []

        
        
    def SaveConfig(self, fileName):
        Config = ConfigParser.ConfigParser()
        Config.read(fileName)
        
        # Main
        if not Config.has_section('Main'):
                Config.add_section('Main')
        Config.set('Main', 'File Name', self.fileName)
        if self.fileType == self.FileType.FixedWidth:
            Config.set('Main', 'File Type', 'Fixed Width')
            Config.set('Main', 'Breaks', self.breaks)
        else:
            Config.set('Main', 'File Type', 'CSV')
            
        Config.set('Main', 'Rows', self.__rows)
        Config.set('Main', 'rows - headers', self.nHeader)
        Config.set('Main', 'rows - footers', self.nFooter)

        n = 1
        for i in self.fields:
            thisSection = 'Field {}'.format(n)
            if not Config.has_section(thisSection):
                Config.add_section(thisSection)

            if not Config.has_option(thisSection, 'Name'):
                Config.set(thisSection, 'Name', thisSection)

            Config.set(thisSection, 'Length (allotted)', i['max length'])
            Config.set(thisSection, 'Length (actual)', i['max trim length'])
            if i['nString'] > 0:
                Config.set(thisSection, 'type', 'string')
            elif i['nFloat'] > 0:
                Config.set(thisSection, 'type', 'float')
            elif i['nInt'] > 0:
                Config.set(thisSection, 'type', 'int')
            elif i['nDate'] > 0:
                Config.set(thisSection, 'type', 'date')
                Config.set(thisSection, 'format', self.dateFormat)
            if i['nBlank'] > 0:
                Config.set(thisSection, 'blanks', 'TRUE')
            n += 1

        try:
            oFile = open(fileName, 'wb')
        except:
            logging.critical('Could not open file: %s', fileName)
        else:
            Config.write(oFile)
            oFile.close()
        

    def Analyze(self):
        try:
            fileIn = open(self.fileName)
        except:
            logging.critical('Could not open file: %s', self.fileName)
        else:
            self.__rows = sum(1 for i in fileIn)
            fileIn.seek(0)
            
            self.__blankRows = 0
            self.fields = []

            
            # Skip the header
            if self.fileType == self.FileType.FixedWidth:
                for i in range(self.nHeader):
                    fileIn.readline()

                for i in xrange(self.__rows - self.nHeader - self.nFooter):
                    l = fileIn.readline()
                    l = self.__parser(l)
                    if not self.__isBlankLine(l):
                        self.__analyzeRow(l)
                    else:
                        self.__blankRows += 1
            else:
                csvIn = csv.reader(fileIn)
                # Skip the header
                for i in range(self.nHeader):
                    next(csvIn)
                    
                for i in xrange(self.__rows - self.nHeader - self.nFooter):
                    l = next(csvIn)
                    if not self.__isBlankLine(l):
                        self.__analyzeRow(l)
                    else:
                        self.__blankRows += 1
                
            fileIn.close()

            
    def Rows(self):
        return(self.__rows)

    def BlankRows(self):
        return(self.__blankRows)
    
