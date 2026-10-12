"""Criterios explicitos de equivalencia, sin ocultar NaN ni diferencias de forma."""
import numpy as np

def require_close(name,actual,reference,atol,rtol=0):
    a=np.asarray(actual,float);b=np.asarray(reference,float)
    if a.shape!=b.shape or not np.isfinite(a).all() or not np.isfinite(b).all():
        raise AssertionError(f'{name}: forma incompatible o valor no finito')
    err=abs(a-b);limit=np.asarray(atol)+rtol*abs(b)
    if np.any(err>limit):raise AssertionError(f'{name}: max error {err.max():.6g}, fuera de tolerancia')
    return float(err.max())
