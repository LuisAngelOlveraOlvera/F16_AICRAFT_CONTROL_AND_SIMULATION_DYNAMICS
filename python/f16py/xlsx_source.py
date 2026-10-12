"""Lectura acotada de celdas XLSX NASA candidatas, sólo stdlib, sólo lectura."""
import zipfile,posixpath,re
import xml.etree.ElementTree as ET

def sheet_cells(path,name):
    ns={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
    rn='{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id'
    with zipfile.ZipFile(path) as z:
        wb=ET.fromstring(z.read('xl/workbook.xml'));rels=ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
        sheet=next(s for s in wb.findall('m:sheets/m:sheet',ns) if s.attrib['name']==name)
        target=next(r.attrib['Target'] for r in rels if r.attrib['Id']==sheet.attrib[rn])
        target=target.lstrip('/') if target.startswith('/') else posixpath.normpath('xl/'+target)
        tree=ET.fromstring(z.read(target));cells={}
        for c in tree.findall('.//m:sheetData/m:row/m:c',ns):
            ref=c.attrib['r'];letters,row=re.fullmatch(r'([A-Z]+)([0-9]+)',ref).groups();col=0
            for letter in letters:col=col*26+ord(letter)-64
            v=c.find('m:v',ns)
            if v is not None and c.attrib.get('t','n')=='n':
                try:cells[(int(row),col)]=float(v.text)
                except (ValueError,TypeError):pass
        return cells
