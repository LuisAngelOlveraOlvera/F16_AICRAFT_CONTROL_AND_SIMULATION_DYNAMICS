import unittest
import numpy as np
from matplotlib.backends.backend_agg import FigureCanvasAgg

class States(unittest.TestCase):
    def test_all_states_panels_use_record_values_without_mutation(self):
        from f16py.laboratory.views import StatesView,figure
        from f16py.laboratory.experiments import run_experiment
        r=run_experiment('pid',{'duracion':.02})[0];before=r['X'].copy()
        view=StatesView(figure());view.set_record(r)
        self.assertEqual(len(view.axes),9)
        np.testing.assert_array_equal(view.axes['altitud'].lines[0].get_ydata(),r['altitud_m'])
        np.testing.assert_array_equal(view.axes['aero'].lines[0].get_ydata(),np.degrees(r['X'][:,3]))
        np.testing.assert_array_equal(view.axes['actitud'].lines[0].get_ydata(),np.degrees(r['angulos_rad'][:,0]))
        np.testing.assert_array_equal(view.axes['tasas'].lines[2].get_ydata(),np.degrees(r['X'][:,7]))
        np.testing.assert_array_equal(view.axes['motor'].lines[0].get_ydata(),r['X'][:,0])
        np.testing.assert_array_equal(view.axes['lef'].lines[0].get_ydata(),r['X'][:,1])
        np.testing.assert_array_equal(view.axes['posicion'].lines[1].get_ydata(),r['X'][:,13])
        np.testing.assert_array_equal(view.axes['aero'].lines[2].get_ydata(),r['referencia_alfa_deg'])
        view.cursor(.02)
        for line in view.cursors:self.assertEqual(list(line.get_xdata()),[.02,.02])
        FigureCanvasAgg(view.fig).draw()
        np.testing.assert_array_equal(r['X'],before)

    def test_single_sample_and_references_render(self):
        from f16py.laboratory.views import StatesView,figure
        from f16py.laboratory.experiments import run_experiment
        r=run_experiment('waypoints',{'original':False,'duracion':.02,'waypoints':[[0,0,3000],[100,0,3000]]})[0]
        view=StatesView(figure());view.set_record(r);self.assertEqual(view.cursor(5),0)
        FigureCanvasAgg(view.fig).draw()
        np.testing.assert_array_equal(view.axes['velocidad'].lines[1].get_ydata(),r['referencia'][:,1])

if __name__=='__main__':unittest.main()
