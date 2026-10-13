import unittest
import tkinter as tk
import numpy as np

class Desktop(unittest.TestCase):
    def setUp(self):
        try:self.root=tk.Tk();self.root.withdraw()
        except tk.TclError as e:self.skipTest('Sin display Tk: '+str(e))
        from f16py.laboratory.app import LaboratoryApp
        self.app=LaboratoryApp(self.root)

    def tearDown(self):
        if hasattr(self,'app'):self.app.close()

    def test_tabs_defaults_and_restore(self):
        tabs=[self.app.notebook.tab(t,'text') for t in self.app.notebook.tabs()]
        self.assertEqual(len(tabs),9)
        self.assertIn('Avión',tabs)
        self.assertIn('Estados',tabs)
        self.app.load_profile('pid')
        self.assertEqual(self.app.configuration()['duracion'],15)
        self.app.values['pid.kp'].set('2')
        self.app.restore()
        self.assertEqual(self.app.configuration()['pid']['kp'],5)

    def test_route_reading_and_record_selection(self):
        self.app.load_profile('waypoints')
        cfg=self.app.configuration()
        self.assertEqual(cfg['waypoints'][0],[0,0,3000])
        from f16py.laboratory.experiments import run_experiment
        record=run_experiment('pid',{'duracion':.02})[0]
        self.app.accept_records((record,))
        self.app.save_a()
        self.app.seek(.02)
        self.assertEqual(self.app.current_index,len(record['t'])-1)
        self.assertEqual(self.app.time_value.get(),.02)
        self.assertIsNot(self.app.record_a,record)
        np.testing.assert_array_equal(self.app.record_a['X'],record['X'])

    def test_plot_data_and_worker_cancel(self):
        from f16py.laboratory.worker import ExperimentWorker
        worker=ExperimentWorker()
        worker.start('waypoints',{'duracion':180})
        worker.cancel()
        self.assertFalse(worker.busy)
        self.assertIsNone(worker.poll())

    def test_bad_loaded_record_does_not_replace_previous(self):
        from f16py.laboratory.experiments import run_experiment
        from copy import deepcopy
        record=run_experiment('pid',{'duracion':.02})[0]
        self.app.accept_records((record,))
        bad=deepcopy(record);bad['t']=np.array([0,.02])
        with self.assertRaises(ValueError):self.app.accept_records((bad,))
        self.assertIs(self.app.record_b,record)

    def test_playback_controls_remain_visible_at_minimum_size(self):
        self.root.deiconify();self.root.geometry('920x680');self.app.notebook.select(self.app.tabs['Vuelo y resultados']);self.root.update()
        self.assertTrue(self.app.play_button.winfo_ismapped())
        self.assertTrue(self.app.time_scale.winfo_ismapped())

    def test_states_cursor_and_selection_are_synchronized(self):
        from f16py.laboratory.experiments import run_experiment
        first=run_experiment('pid',{'duracion':.02})[0]
        second=run_experiment('lqr_lateral',{'duracion':.04})[0]
        self.app.accept_records((first,second))
        self.assertEqual(self.app.notebook.select(),str(self.app.tabs['Estados']))
        self.assertIs(self.app.states.record,second)
        self.app.seek(.02)
        for line in self.app.states.cursors:self.assertEqual(list(line.get_xdata()),[.02,.02])
        self.app.record_choice.set(self.app.record_picker.cget('values')[0]);self.app.select_record()
        self.assertIs(self.app.states.record,first)
        self.assertEqual(self.app.time_value.get(),0)
        self.root.deiconify();self.root.geometry('920x680');self.root.update()
        self.assertTrue(self.app.states_play_button.winfo_ismapped())
        self.assertTrue(self.app.states_scale.winfo_ismapped())

if __name__=='__main__':unittest.main()
