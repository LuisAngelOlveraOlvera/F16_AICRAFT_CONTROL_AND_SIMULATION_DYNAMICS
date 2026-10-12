import unittest
import numpy as np
ERRORS={}

class ParityTests(unittest.TestCase):
    def test_demostraciones(self):
        from f16py.demonstrations import pid_demo,longitudinal_demo,comparison_demo
        p=pid_demo(duracion=.02);l=longitudinal_demo(duracion=.02);c=comparison_demo(duracion=.02)
        self.assertEqual(p['X'].shape,(11,15))
        self.assertEqual(p['X'][0,0],0)
        self.assertAlmostEqual(p['X'][0,3],np.radians(2))
        self.assertEqual(l['X'].shape,(11,15))
        self.assertEqual(c['Xp'].shape,(11,6))
        self.assertLess(np.max(abs(c['Hq']-c['He'])),1e-9)

    def test_auditoria_y_transformaciones(self):
        from f16py.audit import lateral_audit,standard_audit,sensitivity_audit,source_audit
        a=lateral_audit();b=standard_audit(a);s=sensitivity_audit(b)
        self.assertLess(a['manual_vs_fd_max'],1e-7)
        self.assertLess(b['verificacion']['covarianza_A_quat'],1e-6)
        self.assertLess(b['verificacion']['covarianza_A_cuerpo'],1e-6)
        self.assertLess(s['pasos'][2]['max_diferencia4'],1e-5)
        from pathlib import Path
        from scipy.io import loadmat
        fixture=loadmat(Path(__file__).resolve().parents[1]/'references'/'paridad.mat',simplify_cells=True)
        for key in ['manual_A','condition_component','remaining_model_component','control_derivatives']:
            np.testing.assert_allclose(a[key],fixture['lat'][key],atol=1e-6,rtol=1e-7)
            ERRORS['lateral_'+key]=float(np.max(abs(a[key]-fixture['lat'][key])))
        for key in ['A14','B14','A15','B15','A18','B18','A_cuerpo15','B_cuerpo15','A9','B9','C9','D9']:
            np.testing.assert_allclose(b['matrices'][key],fixture['estandar']['matrices'][key],atol=2e-6,rtol=1e-7)
            ERRORS['estandar_'+key]=float(np.max(abs(b['matrices'][key]-fixture['estandar']['matrices'][key])))
        for py,mat in zip(s['pasos'],fixture['sensibilidad']['pasos']):
            # Cancellation at 1e-10 is evaluated, not forced to look converged.
            tol=2e-6 if py['h_relativo']>=1e-6 else .003
            np.testing.assert_allclose(py['A4'],mat['A4'],atol=tol,rtol=1e-5)

    def test_fuentes_locales_opcionales(self):
        from pathlib import Path
        from scipy.io import loadmat
        from f16py.audit import source_audit
        root=Path(__file__).resolve().parents[1]
        path=root/'datos_locales'/'Tablas 2.xlsx'
        if not path.is_file():self.skipTest('Tabla original local opcional; no incluida en publicacion')
        f=source_audit(path);fixture=loadmat(root/'references'/'paridad.mat',simplify_cells=True)
        self.assertEqual(len(f['hojas']),12)
        for py,mat in zip(f['hojas'],fixture['fuentes']['hojas']):
            for key in ['dato','ajuste','rmse','valor_trim_ajuste','pendiente_trim_ajuste_por_grado','pendiente_trim_hoja_por_grado']:
                np.testing.assert_allclose(py[key],mat[key],atol=1e-7,rtol=1e-7)

    def test_entradas_y_dryden(self):
        from f16py.execution import ORDER,trajectory
        from pathlib import Path
        root=Path(__file__).resolve().parents[1]
        for name in ORDER:self.assertTrue((root/(name+'.py')).is_file(),name)
        r=trajectory(duracion=.06)
        self.assertEqual(r['config']['tramo'],30)
        from f16py.demonstrations import dryden_pair
        from scipy.io import loadmat
        a,b=dryden_pair()
        ref=loadmat(root/'references'/'dryden_original.mat',simplify_cells=True)['d']['R']
        for r,h in zip([a,b],ref):
            np.testing.assert_allclose(r['H'],h.T,atol=2e-6,rtol=1e-7)
            ERRORS[r['config']['escenario']+'_H']=float(np.max(abs(r['H']-h.T)))

    def test_uniformes_y_ruido_generico(self):
        from pathlib import Path
        from scipy.io import loadmat
        from f16py.simulation import simulate
        root=Path(__file__).resolve().parents[1]
        refs=loadmat(root/'references'/'trayectoria.mat',simplify_cells=True)['r']
        r=simulate(escenario='trayectoria',duracion=.06,tramo=.01)
        np.testing.assert_allclose(r['objetivo'][np.arange(6)*5],refs['objetivo'][np.arange(6)*15000],atol=1e-10)
        w=loadmat(root/'references'/'dryden_original.mat',simplify_cells=True)['d']['W'].T
        for name in ['dryden_abierto','dryden_lqr']:
            original=loadmat(root/'references'/(name+'.mat'),simplify_cells=True)['r']
            r=simulate(escenario=name,duracion=.04,noise_series=w[:20])
            np.testing.assert_allclose(r['X'],original['X'][:21],atol=1e-8)
        with self.assertRaises(ValueError):simulate(escenario='nivelado',duracion=.04,noise_series=w[:20])

    def test_contraste_matlab(self):
        from pathlib import Path
        from scipy.io import loadmat
        from f16py.demonstrations import pid_demo,longitudinal_demo,comparison_demo
        p=Path(__file__).resolve().parents[1]/'references'/'paridad.mat'
        if not p.is_file():self.skipTest('Fixture MATLAB aun no exportado')
        f=loadmat(p,simplify_cells=True)
        for name,fun in [('pid',pid_demo),('lon',longitudinal_demo)]:
            r=fun();np.testing.assert_allclose(r['X'],f[name]['X'].T,atol=2e-7,rtol=1e-8)
            np.testing.assert_allclose(r['U_real'][:,0],f[name]['de_hist'],atol=1e-6,rtol=1e-8)
            ERRORS[name+'_X']=float(np.max(abs(r['X']-f[name]['X'].T)))
            ERRORS[name+'_de']=float(np.max(abs(r['U_real'][:,0]-f[name]['de_hist'])))
        r=comparison_demo()
        for key in ['Hq','He','Xl','Xp','Xk','up','uk']:
            expected=np.asarray(f['cmp'][key]);expected=expected.T if expected.ndim==2 else expected
            np.testing.assert_allclose(r[key],expected,atol=2e-6,rtol=1e-7)
            ERRORS['comparacion_'+key]=float(np.max(abs(r[key]-expected)))

if __name__=='__main__':unittest.main()
