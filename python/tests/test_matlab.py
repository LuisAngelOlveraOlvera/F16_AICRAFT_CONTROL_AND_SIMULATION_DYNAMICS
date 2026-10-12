import unittest
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from f16py import fits
from f16py.dynamics import rhs,environment,quat_to_euler,rhs_euler,rhs_body,rotation,PAR
from f16py.control import trim,design,jacobian

REF=Path(__file__).resolve().parents[1]/'references'/'matlab_reference.mat'

class MatlabComparison(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.ref=loadmat(REF,simplify_cells=True)

    def test_62_ajustes_1054_muestras(self):
        for case in self.ref['fit_cases']:
            with self.subTest(funcion=case['name']):
                f=getattr(fits,case['name']);inputs=np.asarray(case['inputs']).reshape(17,-1)
                py=np.array([f(*v) for v in inputs])
                np.testing.assert_allclose(py,case['outputs'],rtol=2e-13,atol=2e-11)

    def test_20_casos_6dof_momentos_motor_actuadores_viento(self):
        for case in self.ref['cases']:
            x,u=case['x'],case['u']
            np.testing.assert_allclose(rhs(0,x,u),case['dx'],rtol=1e-11,atol=2e-10)
            np.testing.assert_allclose(rhs(0,case['x18'],u),case['dx18'],rtol=1e-11,atol=2e-10)
            np.testing.assert_allclose(rhs(0,x,u,gust=case['gust']),case['dxwind'],rtol=1e-11,atol=2e-10)
            F,T,*_=environment(x,u)
            np.testing.assert_allclose(F,case['loads'],rtol=1e-12,atol=2e-9)
            self.assertAlmostEqual(T,case['thrust'],delta=2e-9)
            omega=x[5:8];I=np.array([[12874.8,0,-1331.4],[0,75673.6,0],[-1331.4,0,85552.1]])
            angular=np.linalg.solve(I,F[[4,5,3]]-np.cross(omega,I@omega)-np.cross(omega,[216.9,0,0]))
            np.testing.assert_allclose(rhs(0,x,u)[5:8],angular,atol=1e-12)

    def test_trim_jacobiano_y_ganancias(self):
        x,u,info=trim();np.testing.assert_allclose(x,self.ref['xt'],atol=1e-8,rtol=1e-9)
        np.testing.assert_allclose(u,self.ref['ut'],atol=1e-8,rtol=1e-9)
        c=design(x,u,True,True)
        np.testing.assert_allclose(c['A14'],self.ref['A14'],atol=2e-6,rtol=1e-6)
        np.testing.assert_allclose(c['B14'],self.ref['B14'],atol=2e-6,rtol=1e-6)
        r=loadmat(REF.parent/'waypoints.mat',simplify_cells=True)['r']
        np.testing.assert_allclose(c['Klon'],r['control']['Klon'],rtol=1e-5,atol=1e-4)
        np.testing.assert_allclose(c['Klat'],r['control']['Klat'],rtol=1e-5,atol=1e-4)

    def test_A15_B15_y_direccion_radial(self):
        f=loadmat(REF.parent/'jacobiano15.mat',simplify_cells=True);x,u=f['x'],f['u']
        A=jacobian(lambda z:rhs(0,z,u),x);B=jacobian(lambda v:rhs(0,x,v),u)
        np.testing.assert_allclose(A,f['A15'],rtol=1e-6,atol=2e-6)
        np.testing.assert_allclose(B,f['B15'],rtol=1e-6,atol=2e-6)
        for case in f['radial']:np.testing.assert_allclose(rhs(0,case['x'],u),case['dx'],atol=1e-10)

    def test_transformaciones_euler_y_cuerpo(self):
        for case in self.ref['cases']:
            x,u=case['x'],case['u'];e=quat_to_euler(x);d=rhs(0,x,u);de=rhs_euler(0,e,u)
            np.testing.assert_allclose(de[:8],d[:8],atol=1e-10)
            np.testing.assert_allclose(de[11:14],d[12:15],atol=1e-10)
            V,a,b=x[2:5];vel=V*np.array([np.cos(a)*np.cos(b),np.sin(b),np.sin(a)*np.cos(b)])
            xb=np.r_[vel,x[5:8],x[8:12],x[12:15]];db=rhs_body(0,xb,u,x[1])
            F,T,*_=environment(x,u);expected=F[:3]/PAR[0]+rotation(x[8:12]).T@[0,0,PAR[1]]-np.cross(x[5:8],vel)
            np.testing.assert_allclose(db[:3],expected,atol=1e-11)
            # Modelo auxiliar SIN empuje; agregarlo solo para identidad fisica.
            converted=np.array([np.cos(a)*np.cos(b)*d[2]-V*np.sin(a)*np.cos(b)*d[3]-V*np.cos(a)*np.sin(b)*d[4],
                np.sin(b)*d[2]+V*np.cos(b)*d[4],np.sin(a)*np.cos(b)*d[2]+V*np.cos(a)*np.cos(b)*d[3]-V*np.sin(a)*np.sin(b)*d[4]])
            np.testing.assert_allclose(db[:3]+[T/PAR[0],0,0],converted,atol=1e-10)

if __name__=='__main__':unittest.main()
