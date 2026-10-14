"""Transformación única de perturbaciones UI en estados nativos."""
import numpy as np

def perturb(x,initial):
    from ..dynamics import angles,quaternion
    x=x.copy();a=angles(x[8:12])
    x[3:5]+=np.radians([initial['alpha_deg'],initial['beta_deg']])
    x[5:8]+=np.radians([initial['p_deg_s'],initial['q_deg_s'],initial['r_deg_s']])
    x[8:12]=quaternion(*(a+np.radians([initial['phi_deg'],initial['theta_deg'],initial['psi_deg']])))
    return x
