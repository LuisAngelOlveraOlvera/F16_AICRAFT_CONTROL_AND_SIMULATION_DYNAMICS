"""Pruebas completas de los pasos nuevos; código 1 si un contraste falla."""
import argparse,unittest,sys
from pathlib import Path
from f16py.io import write_json

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--salida',type=Path,required=True);args=ap.parse_args()
    if args.salida.exists():raise FileExistsError(args.salida)
    root=Path(__file__).resolve().parent
    suite=unittest.defaultTestLoader.discover(str(root/'tests'),pattern='test_parity.py')
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    args.salida.mkdir(parents=True)
    write_json(args.salida/'resultado.json',{'estado':'PASS' if result.wasSuccessful() else 'FAIL','pruebas':result.testsRun,
        'fuentes_originales':'NO_EVALUADAS' if any('test_fuentes_locales_opcionales' in t.id() for t,_ in result.skipped) else 'EVALUADAS',
        'errores':len(result.errors),'fallos':len(result.failures),'omitidas':len(result.skipped),
        'diferencias_max_abs':getattr(sys.modules.get('test_parity'),'ERRORS',{}),
        'tolerancias':{'demo_estado_abs':2e-7,'demo_estado_rel':1e-8,'comparacion_abs':2e-6,'auditoria_matrices_abs':2e-6}})
    unexpected=[t for t,_ in result.skipped if 'test_fuentes_locales_opcionales' not in t.id()]
    if not result.wasSuccessful() or unexpected:raise SystemExit(1)
if __name__=='__main__':main()
