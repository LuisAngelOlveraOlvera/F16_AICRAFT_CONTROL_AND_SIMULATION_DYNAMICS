"""Ajustes originales MATLAB: coeficientes sin modificaciones. Generado por tools/portar_ajustes.py."""
from math import exp
def gauss(X,xo,Y,yo,sigma,A):
    return A*exp(-((X-xo)**2+(Y-yo)**2)/sigma**2)

def Cl(alpha,beta,de):
    alpha = float(alpha)
    beta = float(beta)
    de = float(de)
    teta = [-0.000435799168635,0.926430028503601,-0.000002636039899]
    Ym01  = gauss(beta, -30, alpha,  90, 48,  0.0990)
    Ym02  = gauss(beta,  30, alpha,  90, 50, -0.0900)
    Ym03  = gauss(beta, -30, alpha,  22, 24,  0.0800)
    Ym04  = gauss(beta,  30, alpha,  22, 24, -0.0800)
    Ym05  = gauss(beta, -30, alpha, -20, 25, -0.0250)
    Ym06  = gauss(beta,  30, alpha, -20, 25,  0.0250)
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0250)
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0250)
    Ym09  = gauss(beta, -15, alpha,  90, 15, -0.0200)
    Ym010 = gauss(beta,  15, alpha,  90, 15,  0.0200)
    Ym    = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym010
    y = teta[0]+teta[1]*Ym+teta[2]*de
    return y

def Clda(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.014004007568608,0.863027432628062]
    Ym01  = gauss(beta, -30, alpha,  90, 50,  0.0900)
    Ym02  = gauss(beta,  30, alpha,  90, 50, -0.0900)
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0300)
    Ym04  = gauss(beta,  30, alpha,  22, 20, -0.1300)
    Ym05  = gauss(beta, -30, alpha, -20, 25, -0.0550)
    Ym06  = gauss(beta,  30, alpha, -20, 25,  0.0200)
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0150)
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0650)
    Ym09  = gauss(beta, -15, alpha,  90, 15, -0.0200)
    Ym010 = gauss(beta,  15, alpha,  90, 15,  0.0200)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym010
    y = teta[0]+teta[1]*Ym
    return y

def Cldalef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.006940790611846,0.988889095499375]
    Ym01  = gauss(beta, -30, alpha,  45, 50,  0.0800)
    Ym02  = gauss(beta,  30, alpha,  45, 50, -0.0800)
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0001)
    Ym04  = gauss(beta,  30, alpha,  22, 20, -0.0001)
    Ym05  = gauss(beta, -30, alpha, -20, 35, -0.0550)
    Ym06  = gauss(beta,  30, alpha, -20, 30,  0.0500)
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0150)
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0650)
    Ym09  = gauss(beta, -15, alpha,  45, 15, -0.0100)
    Ym10  = gauss(beta,  15, alpha,  45, 15,  0.0100)
    Ym11  = gauss(beta,  30, alpha,  10, 15, -0.0800)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym10 + Ym11
    y = teta[0]+teta[1]*Ym
    return y

def Cldr(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.002486021109881,1.000348960708208]
    Ym01  = gauss(beta, -30, alpha,  90, 50,  0.0900)
    Ym02  = gauss(beta,  30, alpha,  90, 50, -0.0900)
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0900)
    Ym04  = gauss(beta,  30, alpha,  28, 20, -0.0300)
    Ym05  = gauss(beta, -30, alpha, -20, 35, -0.0200)
    Ym06  = gauss(beta,  30, alpha, -20, 30,  0.0600)
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0350)
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0350)
    Ym09  = gauss(beta, -15, alpha,  90, 15, -0.0100)
    Ym10  = gauss(beta,  15, alpha,  90, 15,  0.0100)
    Ym11  = gauss(beta,  30, alpha,  10, 15, -0.0800)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym10 + Ym11
    y = teta[0]+teta[1]*Ym
    return y

def Cllef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.001243947996349,1.014224957479365]
    Ym01  = gauss(beta, -30, alpha,  45, 50,  0.0600)
    Ym02  = gauss(beta,  30, alpha,  45, 50, -0.0600)
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0300)
    Ym04  = gauss(beta,  30, alpha,  22, 20, -0.0300)
    Ym05  = gauss(beta, -30, alpha, -20, 20, -0.0380)
    Ym06  = gauss(beta,  30, alpha, -20, 20,  0.0480)
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0250)
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0250)
    Ym09  = gauss(beta, -15, alpha,  45, 15, -0.0200)
    Ym010 = gauss(beta,  15, alpha,  45, 15,  0.0200)
    Ym    = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym010
    y = teta[0]+teta[1]*Ym
    return y

def Clp(alpha):
    alpha = float(alpha)
    teta = [-0.3488,0.0044,-2e-5]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Clr(alpha):
    alpha = float(alpha)
    teta = [0.0424,0.0096,-0.0001]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cm(alpha,beta,de):
    alpha = float(alpha)
    beta = float(beta)
    de = float(de)
    teta = [-0.053016014965495,-0.000241978499145,0.000244041048684,0.000115479727957,-0.000002538683564,0.000000000000008,-0.005433237569061]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7+teta[6]*de
    return y

def Cmlef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.027090750432187,-0.000178931585292,0.000986056281143,-0.000005706787715,-0.000003396643484,0.000000000000570]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7
    return y

def Cmq(alpha):
    alpha = float(alpha)
    teta = [-6.0883,0.0029,0.0002]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cn(alpha,beta,de):
    alpha = float(alpha)
    beta = float(beta)
    de = float(de)
    teta = [-0.001440372540832,0.395674436639150,-0.000000682405010]
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1790)
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1790)
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.2200)
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.2200)
    Ym05 = gauss(beta,  30, alpha, 90, 45, -0.0300)
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0300)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym+teta[2]*de
    return y

def Cnda(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.000454321190216,0.823762651935457]
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1000)
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1000)
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1300)
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1100)
    Ym05 = gauss(beta,  30, alpha, 90, 40, -0.00700)
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0300)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cndalef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.001364218115686,0.870921134743448]
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1000)
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1000)
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1300)
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1100)
    Ym05 = gauss(beta,  30, alpha, 90, 40,  0.0100)
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0200)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cndr(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.007824271793252,0.850640977402249]
    Ym01 = gauss(beta,  15, alpha, 36, 10, -0.1000)
    Ym02 = gauss(beta, -15, alpha, 36, 16,  0.0900)
    Ym03 = gauss(beta, -30, alpha,  6, 32, -0.1500)
    Ym04 = gauss(beta,  30, alpha,  6, 14,  0.0800)
    Ym05 = gauss(beta,  30, alpha, 90, 40, -0.0200)
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0200)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cnlef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.000353759398496,0.907026824141920]
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.0500)
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.0500)
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1200)
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1200)
    Ym05 = gauss(beta,  30, alpha, 45, 30, -0.0300)
    Ym06 = gauss(beta, -30, alpha, 45, 30,  0.0300)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cnp(alpha):
    alpha = float(alpha)
    teta = [0.0261,0.0016,-3e-5]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cnr(alpha):
    alpha = float(alpha)
    teta = [-0.5342,-0.0054,0.0001]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cx(alpha,beta,de):
    alpha = float(alpha)
    beta = float(beta)
    de = float(de)
    teta = [-0.058167792386493,-0.000028547600456,0.006491011788641,-0.000029206018766,-0.000000608938486,0.000000000000005,-0.001406325966851]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7+teta[6]*de
    return y

def Cxlef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.010506953719709,0.000023298673900,0.001721766817944,0.000029515725369,-0.000001689841463,0.000000000000148]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7
    return y

def Cxq(alpha):
    alpha = float(alpha)
    teta = [1.8022,0.025,-0.0005]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cy(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.019744634907533,0.866893553554607]
    Ym01 = gauss(beta, -30, alpha,  7, 30,  0.6200)
    Ym02 = gauss(beta,  30, alpha,  7, 30, -0.6200)
    Ym03 = gauss(beta, -30, alpha, 90, 50,  0.3990)
    Ym04 = gauss(beta,  30, alpha, 90, 50, -0.3990)
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1000)
    Ym06 = gauss(beta,  30, alpha, 50, 25, -0.1000)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cyda(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta =[0.011636365548986,0.714314829946665]
    Ym01 = gauss(beta, -30, alpha,  7, 26,  0.8000)
    Ym02 = gauss(beta,  30, alpha,  7, 26, -0.8000)
    Ym03 = gauss(beta, -30, alpha, 90, 50,  0.3990)
    Ym04 = gauss(beta,  30, alpha, 90, 44, -0.500)
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1000)
    Ym06 = gauss(beta,  30, alpha, 50, 25, -0.1000)
    Ym07 = gauss(beta, -30, alpha,-20, 15,  0.2000)
    Ym08 = gauss(beta,  30, alpha,-20, 15, -0.2000)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08
    y = teta[0]+teta[1]*Ym
    return y

def Cydalef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.008355886662505,0.930178282294210]
    Ym01 = gauss(beta, -30, alpha,  7, 26,  0.5000)
    Ym02 = gauss(beta,  30, alpha,  7, 26, -0.5000)
    Ym03 = gauss(beta, -30, alpha, 45, 50,  0.2000)
    Ym04 = gauss(beta,  30, alpha, 45, 44, -0.2000)
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1000)
    Ym06 = gauss(beta,  30, alpha, 50, 25, -0.1000)
    Ym07 = gauss(beta, -30, alpha,-20, 15,  0.2000)
    Ym08 = gauss(beta,  30, alpha,-20, 15, -0.2000)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08
    y = teta[0]+teta[1]*Ym
    return y

def Cydr(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.063506096652943,0.790357271432444]
    Ym01 = gauss(beta, -30, alpha,  7, 30,  0.7000)
    Ym02 = gauss(beta,  30, alpha,  7, 30, -0.7000)
    Ym03 = gauss(beta, -30, alpha, 90, 50,  0.3990)
    Ym04 = gauss(beta,  30, alpha, 90, 50, -0.3990)
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1200)
    Ym06 = gauss(beta,  30, alpha, 50, 20, -0.0300)
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06
    y = teta[0]+teta[1]*Ym
    return y

def Cylef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [0.008757883384847,0.862109391055227]
    Ym01 = gauss(beta, -30, alpha,   7, 20,  0.400)
    Ym02 = gauss(beta,  30, alpha,   7, 20, -0.400)
    Ym03 = gauss(beta, -30, alpha,  45, 50,  0.3990)
    Ym04 = gauss(beta,  30, alpha,  45, 50, -0.3990)
    Ym05 = gauss(beta, -30, alpha,  30, 25, -0.1000)
    Ym06 = gauss(beta,  30, alpha,  30, 25, -0.1000)
    Ym07 = gauss(beta, -30, alpha, -20, 35,  0.3000)
    Ym08 = gauss(beta,  30, alpha, -20, 35, -0.3000)
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08
    y = teta[0]+teta[1]*Ym
    return y

def Cyp(alpha):
    alpha = float(alpha)
    teta = [0.1286,0.0145,-0.0002]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cyr(alpha):
    alpha = float(alpha)
    teta = [1.0038,-0.0405,0.0003]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Cz(alpha,beta,de):
    alpha = float(alpha)
    beta = float(beta)
    de = float(de)
    teta = [-0.091238995686850,-0.000425255531389,-0.064942888822511,0.000215918921229,0.000005939707941,-0.000000000000046,-0.006157878453039]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7+teta[6]*de
    return y

def Czlef(alpha,beta):
    alpha = float(alpha)
    beta = float(beta)
    teta = [-0.058427996550182,-0.000574617239301,-0.069490106246787,0.000144828731909,0.000009290975195,0.000000000000058]
    y = teta[0]+teta[1]*beta+teta[2]*alpha+teta[3]*alpha**2+teta[4]*alpha**3+teta[5]*alpha**7
    return y

def Czq(alpha):
    alpha = float(alpha)
    teta = [-29.289,-0.3097,0.0063]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dClb(alpha):
    alpha = float(alpha)
    teta = [9e-5,3e-6,-6e-8]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dClda(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Clda(alfa,beta)-Cl(alfa,beta,0)
    return y

def dCldalef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cldalef(alfa,beta)-Cllef(alfa,beta)-dClda(alfa,beta)
    return y

def dCldr(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cldr(alfa,beta)-Cl(alfa,beta,0)
    return y

def dCllef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cllef(alfa,beta)-Cl(alfa,beta,0)
    return y

def dClplef(alpha):
    alpha = float(alpha)
    teta = [-0.0071,0.0007,8e-5]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dClrlef(alpha):
    alpha = float(alpha)
    teta = [0.1293,0.0003,-0.0004]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCm(alpha):
    alpha = float(alpha)
    teta = [0.0225,0.0012,-9e-6]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCmds(alpha,de):
    alpha = float(alpha)
    de = float(de)
    teta = [0.004587286384687,0.848489391522845]
    Ym01 = gauss(de,   0, alpha, 70, 26,  0.1250)
    Ym02 = gauss(de, -25, alpha, 90, 20, -0.0300)
    Ym03 = gauss(de,  25, alpha, 90, 20, -0.0650)
    Ym   = Ym01+Ym02+Ym03
    y = teta[0]+teta[1]*Ym
    return y

def dCmlef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cmlef(alfa,beta)-Cm(alfa,beta,0)
    return y

def dCmqlef(alpha):
    alpha = float(alpha)
    teta = [0.0322,-0.0235,-0.0004]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCnb(alpha):
    alpha = float(alpha)
    teta = [3e-6,1e-6,-1e-8]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCnda(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cnda(alfa,beta)-Cn(alfa,beta,0)
    return y

def dCndalef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cndalef(alfa,beta)-Cnlef(alfa,beta)-Cnda(alfa,beta)
    return y

def dCndr(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cndr(alfa,beta)-Cn(alfa,beta,0)
    return y

def dCnlef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cnlef(alfa,beta)-Cn(alfa,beta,0)
    return y

def dCnplef(alpha):
    alpha = float(alpha)
    teta = [0.0076,-0.0012,0.0002]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCnrlef(alpha):
    alpha = float(alpha)
    teta = [0.0053,-0.008,0.0002]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCxlef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cxlef(alfa,beta)-Cx(alfa,beta,0)
    return y

def dCxqlef(alpha):
    alpha = float(alpha)
    teta = [-1.79,-0.0191,0.0011]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCyda(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cyda(alfa,beta)-Cy(alfa,beta)
    return y

def dCydalef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cydalef(alfa,beta)-Cy(alfa,beta)-dCyda(alfa,beta)
    return y

def dCydr(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cydr(alfa,beta)-Cy(alfa,beta)
    return y

def dCylef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Cylef(alfa,beta)-Cy(alfa,beta)
    return y

def dCyplef(alpha):
    alpha = float(alpha)
    teta = [-0.0382,0.0026,-0.0002]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCyrlef(alpha):
    alpha = float(alpha)
    teta = [-0.0872,0.0217,-0.0005]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def dCzlef(alfa,beta):
    alfa = float(alfa)
    beta = float(beta)
    y=Czlef(alfa,beta)-Cz(alfa,beta,0)
    return y

def dCzqlef(alpha):
    alpha = float(alpha)
    teta = [3.0946,-0.5266,0.0102]
    y = teta[0]+teta[1]*alpha+teta[2]*alpha**2
    return y

def Funcion_Tidle(mach,altitud):
    mach = float(mach)
    altitud = float(altitud)
    teta = [-0.021679531721873,0.986808569463947]
    Ym1  = gauss01(altitud, 0.0000,mach, 1.0, 0.40, -1.6000)
    Ym2  = gauss01(altitud, 0.0000,mach, 0.2, 0.60,  0.3500)
    Ym3  = gauss01(altitud, 1.5240,mach, 0.2, 0.75,  0.7000)
    Ym4  = gauss01(altitud, 1.5240,mach, 1.0, 0.30,  0.1000)
    Ym5  = gauss01(altitud, 0.6096,mach, 0.8, 0.30, -0.4000)
    Ym = Ym1 + Ym2 + Ym3 + Ym4 + Ym5
    y = teta[0]+teta[1]*Ym
    y = y*1e4
    return y

def Funcion_Tmax(mach,altitud):
    mach = float(mach)
    altitud = float(altitud)
    teta = [0.079015880381970,0.976546246176990]
    Ym1  = 12.30-1*gauss01(altitud, 0.0000,mach, 1.0, 1.0, -5.5)
    Ym2  =      -1*gauss01(altitud, 1.5240,mach, 0.2, 2.0, 11.4)
    Ym3  =      -1*gauss01(altitud, 1.5240,mach, 1.0, 0.4,  1.0)
    Ym4  =      -1*gauss01(altitud, 0.0000,mach, 0.2, 0.2, -0.5)
    Ym   = Ym1 + Ym2 + Ym3 + Ym4
    y    = teta[0]+teta[1]*Ym
    y=y*1e4
    return y

def Funcion_Tmil(mach,altitud):
    mach = float(mach)
    altitud = float(altitud)
    teta = [0.016212936579475,1.005049730845808]
    Ym1  = 7.3500-1*gauss01(altitud, 0.6000,mach, 0.2, 6.0, 1.800)
    Ym2  =       -1*gauss01(altitud, 0.6000,mach, 1.0, 6.0, 2.000)
    Ym3  =       -1*gauss01(altitud, 1.5240,mach, 0.2, 1.5, 3.800)
    Ym4  =       -1*gauss01(altitud, 0.0000,mach, 1.0, 1.5,-2.500)
    Ym5  =       -1*gauss01(altitud, 0.0000,mach, 0.2, 0.4,-1.500)
    Ym6  =       -1*gauss01(altitud, 1.5240,mach, 1.0, 0.4, 0.700)
    Ym   = Ym1 + Ym2 + Ym3 + Ym4 + Ym5 + Ym6
    y    = teta[0]+teta[1]*Ym
    y = y*1e4
    return y

def gauss01(X,xo,Y,yo,sigma,A):
    X = float(X)
    xo = float(xo)
    Y = float(Y)
    yo = float(yo)
    sigma = float(sigma)
    A = float(A)
    Y = A*exp( -( (X-xo)**2+(Y-yo)**2 )/sigma**2 )
    return Y
