"""Casos comunes sin viento para la prueba opcional del laboratorio MATLAB."""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scipy.io import savemat
from f16py.laboratory.experiments import run_experiment
from f16py.laboratory.profiles import defaults


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--salida', type=Path, required=True)
    args = parser.parse_args()
    cases = []
    for scenario in ('pid_alfa', 'lateral_lqr', 'autopiloto', 'manual'):
        cfg = defaults('generico')
        cfg.update(escenario=scenario, duracion=.2)
        if scenario == 'lateral_lqr':
            cfg['initial'].update(beta_deg=2., phi_deg=10.)
        elif scenario == 'autopiloto':
            cfg['reference']['time_s'] = 0.
        elif scenario == 'manual':
            cfg['manual'].update(elevador_deg=2., throttle=.4)
        r = run_experiment('generico', cfg)[0]
        cases.append(dict(config_json=json.dumps(cfg), t=r['t'], X=r['X'],
                          U=r['U_real'], referencia=r['referencia']))
    if args.salida.exists():
        raise FileExistsError(args.salida)
    args.salida.parent.mkdir(parents=True, exist_ok=True)
    savemat(args.salida, {'cases': cases}, oned_as='column')
    print(f'PARIDAD PYTHON: 4 casos exportados a {args.salida}')


if __name__ == '__main__':
    main()
