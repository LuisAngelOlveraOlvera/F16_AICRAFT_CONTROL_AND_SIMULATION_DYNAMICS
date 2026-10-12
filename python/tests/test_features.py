import tempfile
import unittest
from pathlib import Path
import numpy as np
from f16py.simulation import simulate,SCENARIOS
from f16py.io import save_record,load_record
from f16py.dynamics import engine_rate,power_command,atmosphere,quaternion,rhs,rkf_step,PAR
from f16py.control import trim,jacobian

class Features(unittest.TestCase):
    def test_tramos_decimales_y_validacion_estricta(self):
        r=simulate(escenario='trayectoria',duracion=.6,paso=.02,tramo=.1,
            targets=[[3000+j,170,0] for j in range(6)])
        self.assertEqual(r['objetivo'][25,0],3005)
        from f16py.validation import require_close
        with self.assertRaises(AssertionError):require_close('K',[1.,2.],[1.,2.01],1e-4)
        with self.assertRaises(AssertionError):require_close('dx',[np.nan],[0.],1e-4)
        with self.assertRaises(ValueError):simulate(escenario='trayectoria',duracion=.02,targets=[[3000,180,0]])

    def test_rhs_no_normaliza_cuaternion_del_estado(self):
        from math import sin,cos,asin,atan2
        from f16py.dynamics import environment
        x,u,_=trim();x[8:12]=1.01*quaternion(.12,.17,0)
        w,q1,q2,q3=x[8:12];pitch=asin(2*(w*q2-q1*q3))
        phi=atan2(2*(w*q1+q2*q3),w*w-q1*q1-q2*q2+q3*q3)
        F,T,*_=environment(x,u);a,b=x[3:5]
        D=-F[0]*cos(a)*cos(b)-F[1]*sin(b)-F[2]*sin(a)*cos(b)
        gravity=PAR[1]*(-cos(a)*cos(b)*sin(pitch)+sin(b)*sin(phi)*cos(pitch)+sin(a)*cos(b)*cos(phi)*cos(pitch))
        expected=(-D+T*cos(a)*cos(b))/PAR[0]+gravity
        self.assertAlmostEqual(rhs(0,x,u)[2],expected,places=11)

    def test_pid_y_salidas_lineales(self):
        from f16py.control import pid_alpha,alpha_reference,linearize
        u,integ=pid_alpha(3,np.radians(2),0,0,.1,.2)
        self.assertAlmostEqual(u[0],-5.15);self.assertAlmostEqual(integ,.1)
        u,integ=pid_alpha(8,0,0,0,.1,.2)
        self.assertEqual(u[0],-25);self.assertEqual(integ,0)
        self.assertEqual(alpha_reference(170,-3000),3)
        self.assertEqual(alpha_reference(80,-3000),8)
        x,u,_=trim();A,B,C,D=linearize(x,u)
        self.assertEqual(A.shape,(15,15));self.assertEqual(B.shape,(15,4))
        self.assertEqual(C.shape,(3,15));self.assertEqual(D.shape,(3,4))
        self.assertAlmostEqual(C[1,6],1,places=9)

    def test_motor_fronteras(self):
        self.assertAlmostEqual(power_command(.77),50.0038,places=10)
        self.assertAlmostEqual(engine_rate(10,.8),5.,places=10)
        self.assertAlmostEqual(engine_rate(60,.2),-100.,places=10)
        self.assertAlmostEqual(engine_rate(90,1),50.,places=10)
        self.assertAlmostEqual(atmosphere(12000)[0],216.65,places=10)

    def test_once_escenarios_y_18_actuadores(self):
        for name in SCENARIOS:
            with self.subTest(escenario=name):
                r=simulate(escenario=name,duracion=.04)
                self.assertTrue(np.isfinite(r['X']).all())
                self.assertEqual(r['X'].shape[1],18 if name in ('autopiloto','trayectoria','waypoints') else 15)
                self.assertLess(max(abs(r['norma_cuaternion']-1)),1e-8)

    def test_rng_local_y_rafaga_explicita(self):
        np.random.seed(123);before=np.random.get_state()
        a=simulate(escenario='dryden_lqr',duracion=.04,semilla=7)
        b=simulate(escenario='dryden_lqr',duracion=.04,semilla=7)
        after=np.random.get_state();np.testing.assert_array_equal(before[1],after[1])
        np.testing.assert_array_equal(a['X'],b['X']);np.testing.assert_array_equal(a['rafaga_m_s'],b['rafaga_m_s'])
        c=simulate(escenario='dryden_lqr',duracion=.04,gust_series=a['rafaga_m_s'])
        np.testing.assert_allclose(a['X'],c['X'],atol=1e-12)

    def test_npz_roundtrip_y_no_sobrescritura(self):
        r=simulate(escenario='nivelado',duracion=.02)
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'nuevo';save_record(r,p);s=load_record(p/'registro.npz')
            np.testing.assert_array_equal(r['X'],s['X']);self.assertEqual(r['config'],s['config'])
            with self.assertRaises(FileExistsError):save_record(r,p)

    def test_limits_y_config_invalidas(self):
        for opts in [{'paso':0},{'duracion':np.nan},{'waypoints_ned':[[0,0,-3000],[0,0,-3100]]},
                     {'posicion_inicial_ned':[0,0,-2000]},{'semilla':-1}]:
            with self.subTest(opts=opts),self.assertRaises(ValueError):simulate(**opts)
        x,u,_=trim();x=np.r_[x,[0,0,0]];d=rhs(0,x,[100,100,100,u[3]])
        np.testing.assert_allclose(d[15:18],[60,80,120])

    def test_paso_y_jacobianos(self):
        x,u,_=trim();x[8:12]=quaternion(.1,.05,.03);x[4]=.02
        a=x.copy();b=x.copy()
        for k in range(100):a=rkf_step(rhs,k*.002,.002,a,u)
        for k in range(200):b=rkf_step(rhs,k*.001,.001,b,u)
        np.testing.assert_allclose(a,b,atol=1e-8,rtol=1e-8)
        A=jacobian(lambda z:rhs(0,z,u),x,1e-5,4);B=jacobian(lambda z:rhs(0,z,u),x,1e-6,2)
        np.testing.assert_allclose(A,B,atol=3e-5,rtol=1e-4)

    def test_animacion_y_graficas(self):
        import matplotlib
        matplotlib.use('Agg')
        from f16py.visualization import plots,animate
        r=simulate(escenario='waypoints',duracion=.02)
        with tempfile.TemporaryDirectory() as d:
            figs=plots(r,d);self.assertEqual(len(figs),7)
            animation=animate(r,Path(d)/'smoke.gif',fps=10,speed=1,snapshot=Path(d)/'final.png')
            self.assertLessEqual(len(animation._fig.axes[0].get_zticks()),4)
            from PIL import Image
            with Image.open(Path(d)/'smoke.gif') as im:self.assertGreaterEqual(im.n_frames,1)
            self.assertGreater((Path(d)/'final.png').stat().st_size,10000)

if __name__=='__main__':unittest.main()
