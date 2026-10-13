import unittest
import numpy as np


class Laboratory(unittest.TestCase):
    def test_profiles_keep_readme_defaults(self):
        from f16py.laboratory.profiles import defaults
        expected={'pid':15,'lqr_longitudinal':20,'lqr_lateral':15,'comparacion':15,
                  'autopiloto':40,'dryden_original':30,'trayectoria_original':180,'waypoints':180}
        for profile,duration in expected.items():
            cfg=defaults(profile)
            self.assertEqual(cfg['duracion'],duration)
            self.assertEqual(cfg['paso'],.002)
            self.assertEqual(cfg['VT'],170)
            self.assertEqual(cfg['altitud'],3000)
        cfg=defaults('waypoints');cfg['waypoints'][0][0]=123
        self.assertEqual(defaults('waypoints')['waypoints'][0][0],0)

    def test_original_dispatch_matches_all_readme_experiments(self):
        from f16py.laboratory.experiments import run_experiment
        from f16py.demonstrations import pid_demo,longitudinal_demo,comparison_demo,dryden_pair
        from f16py.execution import trajectory
        from f16py.simulation import simulate
        direct={'pid':lambda:pid_demo(.02),'lqr_longitudinal':lambda:longitudinal_demo(.02),
          'comparacion':lambda:comparison_demo(.02),'lqr_lateral':lambda:simulate(escenario='lateral_lqr',duracion=.02),
          'autopiloto':lambda:simulate(escenario='autopiloto',duracion=.02),
          'waypoints':lambda:simulate(escenario='waypoints',duracion=.02),
          'trayectoria_original':lambda:trajectory(.02),
          'dryden_original':lambda:dryden_pair(.02)}
        for profile,fun in direct.items():
            with self.subTest(profile=profile):
                actual=run_experiment(profile,{'duracion':.02})
                expected=fun();expected=expected if isinstance(expected,tuple) else (expected,)
                self.assertEqual(len(actual),len(expected))
                for a,e in zip(actual,expected):
                    for key in ['t','X','U_real','referencia','rafaga_m_s']:
                        np.testing.assert_array_equal(a[key],e[key])
                    self.assertEqual(a['laboratorio']['perfil'],profile)

    def test_aircraft_values_are_model_values(self):
        from f16py.laboratory.experiments import aircraft_data
        from f16py.dynamics import PAR
        data=aircraft_data()
        self.assertEqual(data['masa_kg'],PAR[0])
        self.assertEqual(data['peso_N'],PAR[0]*PAR[1])
        self.assertEqual(data['envergadura_m'],PAR[4])
        self.assertEqual(data['Ix_kg_m2'],12874.8)
        self.assertIsNone(data['longitud_real_m'])

    def test_custom_initial_and_reference(self):
        from f16py.laboratory.experiments import run_experiment
        a=run_experiment('lqr_lateral',{'original':False,'duracion':.02,'initial':{'phi_deg':5,'beta_deg':1}})[0]
        self.assertAlmostEqual(np.degrees(a['angulos_rad'][0,0]),5)
        self.assertAlmostEqual(np.degrees(a['X'][0,4]),1)
        b=run_experiment('autopiloto',{'original':False,'duracion':.02,'reference':{'time_s':0,'delta_h_m':50,'delta_psi_deg':10}})[0]
        self.assertEqual(b['objetivo'][0,0],3050)
        self.assertAlmostEqual(np.degrees(b['objetivo'][0,2]),10)

    def test_pid_and_weights_are_editable_without_changing_defaults(self):
        from f16py.laboratory.experiments import run_experiment
        a=run_experiment('pid',{'duracion':.02})[0]
        b=run_experiment('pid',{'original':False,'duracion':.02,'pid':{'kp':2}})[0]
        self.assertNotEqual(a['U_real'][0,0],b['U_real'][0,0])
        a=run_experiment('lqr_lateral',{'duracion':.02})[0]
        b=run_experiment('lqr_lateral',{'original':False,'duracion':.02,'weights':{'r_lat':2}})[0]
        self.assertGreater(np.max(abs(a['control']['Klat']-b['control']['Klat'])),1e-3)

    def test_zero_dryden_sigma_and_reproducibility(self):
        from f16py.laboratory.experiments import run_experiment
        c={'original':False,'escenario':'dryden_lqr','duracion':.02,'turbulence':{'sigma_u':0,'sigma_v':0,'sigma_w':0}}
        a=run_experiment('generico',c)[0]
        np.testing.assert_array_equal(a['rafaga_m_s'],0)
        c['turbulence']['sigma_w']=3
        a=run_experiment('generico',c)[0];b=run_experiment('generico',c)[0]
        np.testing.assert_array_equal(a['X'],b['X'])

    def test_reject_invalid_and_original_edits(self):
        from f16py.laboratory.experiments import run_experiment
        invalid=[{'duracion':float('nan')},{'VT':180},{'duracion':.021},
          {'original':False,'weights':{'q_lon':0}},{'original':False,'turbulence':{'length_u':0}},
          {'semilla':True},{'original':False,'escenario':'waypoints','waypoints':[[0,0,3000],[0,0,3000]]}]
        for cfg in invalid:
            with self.subTest(cfg=cfg),self.assertRaises(ValueError):run_experiment('waypoints',cfg)

    def test_manual_commands_are_applied_and_bounded(self):
        from f16py.laboratory.experiments import run_experiment
        cfg={'escenario':'manual','duracion':.02,'manual':{'elevador_deg':2,'throttle':.4}}
        r=run_experiment('generico',cfg)[0]
        self.assertEqual(r['config']['escenario'],'manual')
        np.testing.assert_array_equal(r['U_real'][0],[2,0,0,.4])
        cfg['manual']['elevador_deg']=30
        with self.assertRaises(ValueError):run_experiment('generico',cfg)

    def test_unknown_groups_and_irrelevant_options_are_rejected(self):
        from f16py.laboratory.experiments import run_experiment
        for cfg in [{'original':False,'pid':'bad'}, {'original':False,'escenario':'nivelado','turbulence':{'sigma_u':4}}]:
            with self.subTest(cfg=cfg),self.assertRaises(ValueError):run_experiment('generico',cfg)

    def test_ignored_top_level_and_lateral_weights_are_rejected(self):
        from f16py.laboratory.experiments import run_experiment
        cases=[('lqr_longitudinal',{'weights':{'q_lat':2}}),('comparacion',{'weights':{'r_lat':2}}),
          ('pid',{'semilla':12}),('pid',{'tramo':10}),
          ('generico',{'escenario':'nivelado','anticipacion_m':100}),
          ('generico',{'escenario':'nivelado','posicion_inicial':[1,2,3000]}),
          ('generico',{'escenario':'nivelado','waypoints':[[1,2,3000],[500,0,3000]]}),
          ('autopiloto',{'reference':{'gamma_deg':6}})]
        for profile,cfg in cases:
            with self.subTest(profile=profile,cfg=cfg),self.assertRaises(ValueError):
                run_experiment(profile,dict(cfg,original=False,duracion=.004))

    def test_loaded_schema_rejects_alpha_reference_and_numeric_strings(self):
        from copy import deepcopy
        from f16py.laboratory.experiments import run_experiment,validate_record
        r=run_experiment('pid',{'duracion':.004})[0]
        bad=deepcopy(r);bad['referencia_alfa_deg']=bad['referencia_alfa_deg'][:-1]
        with self.assertRaises(ValueError):validate_record(bad)
        for path in [('config','VT'),('metricas','rms_altitud_m')]:
            bad=deepcopy(r);bad[path[0]][path[1]]='170'
            with self.assertRaises(ValueError):validate_record(bad)

    def test_already_captured_waypoint_record_is_valid(self):
        from f16py.laboratory.experiments import run_experiment,validate_record
        r=run_experiment('waypoints',{'original':False,'duracion':.02,'waypoints':[[0,0,3000],[100,0,3000]]})[0]
        self.assertEqual(len(r['t']),1)
        self.assertTrue(r['metricas']['ruta_completada'])
        self.assertIs(validate_record(r),r)

    def test_comparison_view_includes_original_control_curves(self):
        from f16py.laboratory.experiments import run_experiment
        from f16py.laboratory.views import figure,plot_comparison
        r=run_experiment('comparacion',{'duracion':.004})[0]
        ax=plot_comparison(figure(),None,r,'Alfa [°]')
        labels=[line.get_label() for line in ax.lines]
        for label in ('Euler','Lineal abierto','Lineal + PID','Lineal + LQR'):self.assertIn(label,labels)


if __name__=='__main__':unittest.main()
