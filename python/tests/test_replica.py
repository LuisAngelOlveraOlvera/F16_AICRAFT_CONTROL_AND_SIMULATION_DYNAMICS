import unittest
import numpy as np


class ReplicaTests(unittest.TestCase):
    def test_trim_y_equilibrio(self):
        from f16py.control import trim
        from f16py.dynamics import rhs
        x,u,info=trim(170,3000)
        self.assertTrue(info['converge'])
        self.assertLess(np.max(np.abs(rhs(0,x,u)[:8])),1e-6)
        self.assertAlmostEqual(np.degrees(x[3]),2.884,delta=.05)

    def test_pose_ejes(self):
        from f16py.dynamics import pose_enu
        t=pose_enu([1,0,0,0],[100,200,-300])
        np.testing.assert_allclose(t[:3,3],[200,100,300],atol=1e-12)
        np.testing.assert_allclose(t[:3,0],[0,1,0],atol=1e-12)

    def test_captura_lateral(self):
        from f16py.simulation import simulate
        r=simulate(escenario='waypoints',duracion=40,paso=.004,
            waypoints_ned=[[0,0,-3000],[12000,0,-3000]],
            posicion_inicial_ned=[0,200,-3000])
        self.assertLess(abs(r['X'][-1,13]),50)
        self.assertEqual(r['X'].shape[1],18)


if __name__=='__main__': unittest.main()
