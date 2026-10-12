"""Graficas de vuelo y animacion de dos vistas: ENU km + actitud cuerpo m."""
from pathlib import Path
import shutil
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation,FFMpegWriter,PillowWriter
from matplotlib.ticker import MaxNLocator,FormatStrFormatter
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from .dynamics import pose_enu

def plots(r,folder=None):
    t=r['t'];X=r['X'];figs={};deg=180/np.pi
    def figure(name,shape):
        f,ax=plt.subplots(*shape,figsize=(12,8),layout='constrained');figs[name]=f
        return ax.ravel()
    def lines(ax,y,title,unit,labels=None):
        ix=np.unique(np.round(np.linspace(0,len(t)-1,min(6000,len(t)))).astype(int))
        ax.plot(t[ix],np.asarray(y)[ix]);ax.set(title=title,xlabel='t [s]',ylabel=unit);ax.grid(True)
        if labels:ax.legend(labels,fontsize=8)
    a=figure('estados',(3,3))
    items=[(r['altitud_m'],'Altitud','h [m]',None),(X[:,2],'Velocidad','VT [m/s]',None),
        (r['Mach'],'Mach','[-]',None),(X[:,3:5]*deg,'Angulos aerodinamicos','[deg]',['alpha','beta']),
        (r['angulos_rad'][:,:2]*deg,'Actitud','[deg]',['phi','theta']),
        (np.unwrap(r['angulos_rad'][:,2])*deg,'Rumbo','[deg]',None),
        (X[:,5:8]*deg,'Tasas cuerpo','[deg/s]',['p','q','r']),
        (r['qbar_Pa']/1000,'Presion dinamica','[kPa]',None),
        ((r['norma_cuaternion']-1)*1e14,'Deriva norma Q','(norma-1) x 1e14',None)]
    for ax,item in zip(a,items):lines(ax,*item)
    if 'referencia_alfa_deg' in r:
        a=figure('pid_alfa',(1,2))
        lines(a[0],np.column_stack([X[:,3]*deg,r['referencia_alfa_deg']]),'Seguimiento PID alpha','[deg]',['Real','Ref'])
        lines(a[1],r['U_real'][:,0],'Elevador PID','[deg]')
    a=figure('mandos',(3,2))
    for j,label in enumerate(['Elevador','Aleron','Timon']):
        lines(a[j],np.column_stack([r['U_comando'][:,j],r['U_acotado'][:,j],r['U_real'][:,j]]),label,'[deg]',['Bruto','Acotado','Real'])
    lines(a[3],r['U_real'][:,3],'Throttle','[0,1]');lines(a[4],X[:,0],'Potencia P3','[%]');lines(a[5],r['LEF_deg'],'LEF','[deg]')
    a=figure('cargas',(3,2))
    items=[(r['fuerzas_N']/1000,'Fuerzas cuerpo','[kN]',['X','Y','Z']),
        (r['momentos_Nm']/1000,'Momentos','[kNm]',['L','M','N']),
        (r['especifica_cuerpo_m_s2'],'Fuerza especifica con empuje','[m/s2]',['x','y','z']),
        (r['aceleracion_inercial_m_s2'],'Aceleracion NED con gravedad','[m/s2]',['N','E','D']),
        (r['an_g'],'Normal especifica CG','[g]',None),(r['rafaga_m_s'],'Rafaga cuerpo','[m/s]',['ug','vg','wg'])]
    for ax,item in zip(a,items):lines(ax,*item)
    a=figure('seguimiento',(2,3));ref=r['referencia']
    real=[r['altitud_m'],X[:,2],np.unwrap(r['angulos_rad'][:,2])*deg];refs=[ref[:,0],ref[:,1],np.unwrap(ref[:,2])*deg]
    for j in range(3):
        lines(a[j],np.column_stack([real[j],refs[j]]),['Altitud','Velocidad','Rumbo'][j],['m','m/s','deg'][j],['Real','Ref'])
        err=real[j]-refs[j]
        if j==2:err=np.degrees(np.arctan2(np.sin(r['angulos_rad'][:,2]-ref[:,2]),np.cos(r['angulos_rad'][:,2]-ref[:,2])))
        lines(a[j+3],err,'Error '+['h','VT','rumbo'][j],['m','m/s','deg'][j])
    f=plt.figure(figsize=(11,7),layout='constrained');ax=f.add_subplot(projection='3d');figs['trayectoria']=f
    xyz=np.column_stack([X[:,13],X[:,12],r['altitud_m']])/1000;nom=r['ruta_nominal_ned'][:,[1,0,2]]/1000;nom[:,2]*=-1
    ax.plot(*xyz.T,label='Vuelo real',color='#195bae');ax.plot(*nom.T,'k--',label=r['etiqueta_ruta'])
    if 'navegacion' in r:
        wp=r['navegacion']['waypoints_ned'][:,[1,0,2]]/1000;wp[:,2]*=-1;ax.scatter(*wp.T,color='gold',edgecolors='black',marker='s',label='Waypoints')
    ax.set(xlabel='Este [km]',ylabel='Norte [km]',zlabel='Altitud [km]',title='Trayectoria 3D ENU');ax.legend(fontsize=8)
    ax.set_box_aspect(np.maximum(np.ptp(np.vstack([xyz,nom]),axis=0),.1));ax.view_init(25,35)
    a=figure('modos',(1,2))
    for ax,kind in zip(a,['lon','lat']):
        z=r['control']['polos_'+kind];ax.scatter(z.real,z.imag);ax.axvline(0,color='black',linestyle=':');ax.grid(True)
        ax.set(title='Polos locales de planta '+kind,xlabel='Re [1/s]',ylabel='Im [1/s]')
    if 'navegacion' in r:
        f,ax=plt.subplots(figsize=(10,4),layout='constrained');figs['error_posicion']=f
        lines(ax,np.column_stack([r['navegacion']['error_transversal_m'],r['navegacion']['error_espacial_m']]),'Distancia a la ruta','[m]',['Horizontal','3D'])
    if folder:
        for name,f in figs.items():
            path=Path(folder)/(name+'.png')
            if path.exists():raise FileExistsError(path)
            f.savefig(path,dpi=120);plt.close(f)
    return figs

def geometry():
    # Misma geometria docente en metros que MATLAB; x adelante,y derecha,z abajo.
    polys=[];xx=[7.4,4,1,-4,-7.4];rr=[.03,.55,.85,.7,.12];theta=np.arange(14)*2*np.pi/14
    rings=[np.column_stack([np.full(14,x),r*np.cos(theta),r*np.sin(theta)]) for x,r in zip(xx,rr)]
    for i in range(4):
        for j in range(14):jj=(j+1)%14;polys.append(np.array([rings[i][j],rings[i][jj],rings[i+1][jj],rings[i+1][j]]))
    polys.extend([np.array(p) for p in [[[2,.6,.2],[-3.2,4.57,.25],[-4.2,4.57,.25],[-3,.6,.2]],
        [[2,-.6,.2],[-3.2,-4.57,.25],[-4.2,-4.57,.25],[-3,-.6,.2]],
        [[-4.5,.5,0],[-6.5,2.7,.1],[-7.3,2.3,.1],[-6.8,.5,0]],
        [[-4.5,-.5,0],[-6.5,-2.7,.1],[-7.3,-2.3,.1],[-6.8,-.5,0]],
        [[-4,0,-.5],[-5.4,0,-3.3],[-6.9,0,-3],[-7.2,0,-.3]],
        [[4,-.35,-.5],[4,.35,-.5],[1,.45,-.9],[1,-.45,-.9]]]])
    return polys

def animate(r,video=None,*,fps=20,speed=12,show=False,snapshot=None):
    if not np.isfinite([fps,speed]).all() or not 0<fps<=60 or speed<=0:raise ValueError('FPS/velocidad invalidos')
    if video and Path(video).exists():raise FileExistsError(video)
    if snapshot and Path(snapshot).exists():raise FileExistsError(snapshot)
    f=plt.figure(figsize=(12,7));ax=f.add_subplot(121,projection='3d');local=f.add_subplot(122,projection='3d')
    f.subplots_adjust(left=.03,right=.98,bottom=.24,top=.90,wspace=.08)
    xyz=np.column_stack([r['X'][:,13],r['X'][:,12],r['altitud_m']])/1000
    nom=r['ruta_nominal_ned'][:,[1,0,2]]/1000;nom[:,2]*=-1
    ax.plot(*xyz.T,color='#cbd6e3',linewidth=1);ax.plot(*nom.T,'k--',linewidth=1)
    if 'navegacion' in r:
        wp=r['navegacion']['waypoints_ned'][:,[1,0,2]]/1000;wp[:,2]*=-1;ax.scatter(*wp.T,c='gold',edgecolors='black',marker='s')
    route='ruta 3D por waypoints' if 'navegacion' in r else 'ruta nominal orientativa'
    ax.set(xlabel='Este [km]',ylabel='Norte [km]',zlabel='Altitud [km]',title='Vuelo real / '+route+'\nENU, kilometros')
    data=np.vstack([xyz,nom]);span=np.maximum(np.ptp(data,axis=0),[.2,.2,.1]);mid=(data.min(0)+data.max(0))/2
    ax.set_xlim(mid[0]-.6*span[0],mid[0]+.6*span[0]);ax.set_ylim(mid[1]-.6*span[1],mid[1]+.6*span[1]);ax.set_zlim(mid[2]-.6*span[2],mid[2]+.6*span[2]);ax.set_box_aspect(span);ax.view_init(25,35)
    for axis in [ax.xaxis,ax.yaxis]:axis.set_major_locator(MaxNLocator(nbins=3));axis.set_tick_params(labelsize=8,pad=1)
    ax.zaxis.set_major_locator(MaxNLocator(nbins=2));ax.zaxis.set_major_formatter(FormatStrFormatter('%.1f'))
    ax.zaxis.set_tick_params(labelsize=8,pad=1)
    local.set(xlim=(-9,9),ylim=(-9,9),zlim=(-7,7),xlabel='Este [m]',ylabel='Norte [m]',zlabel='Arriba [m]',title='Actitud del avion\nGeometria docente, metros');local.set_box_aspect([18,18,14]);local.view_init(24,38)
    local.plot([0,0],[0,7],[0,0],color='gray');local.text(0,7,0,'N');base=geometry()
    model=Poly3DCollection(base,facecolor='#637c92',edgecolor='#506070',linewidth=.15);local.add_collection3d(model)
    trail,=ax.plot([],[],[],color='#195bae',linewidth=2);dot,=ax.plot([],[],[],'o',color='#e55c23')
    hud=f.text(.04,.045,'',family='monospace',fontsize=9,bbox=dict(facecolor='#f0f3f8',edgecolor='#cbd2db'))
    times=np.unique(np.r_[np.arange(0,r['t'][-1]+1e-10,speed/fps),r['t'][-1]])
    ix=np.minimum(len(r['t'])-1,np.floor(times/r['config']['paso']+.5).astype(int))
    def update(j):
        k=ix[j];T=pose_enu(r['X'][k,8:12],r['X'][k,12:15]);model.set_verts([p@T[:3,:3].T for p in base])
        trail.set_data_3d(*xyz[ix[:j+1]].T);dot.set_data_3d(*xyz[k:k+1].T)
        a=np.degrees(r['angulos_rad'][k]);x=r['X'][k];u=r['U_real'][k]
        hud.set_text(f"t={r['t'][k]:7.2f} s  VT={x[2]:6.2f} m/s  h={-x[14]:8.2f} m  Mach={r['Mach'][k]:.3f}  an={r['an_g'][k]:5.2f} g\n"
            f"phi/theta/psi={a[0]:7.2f}/{a[1]:7.2f}/{a[2]:7.2f} deg   alfa/beta={np.degrees(x[3]):6.2f}/{np.degrees(x[4]):6.2f} deg\n"
            f"p/q/r={np.degrees(x[5]):7.2f}/{np.degrees(x[6]):7.2f}/{np.degrees(x[7]):7.2f} deg/s   de/da/dr={u[0]:6.2f}/{u[1]:6.2f}/{u[2]:6.2f} deg\n"
            f"throttle={u[3]:.3f}  P3={x[0]:5.2f}%  LEF={r['LEF_deg'][k]:5.2f} deg  empuje={r['empuje_N'][k]/1000:6.2f} kN")
        return trail,dot,model,hud
    animation=FuncAnimation(f,update,frames=len(ix),interval=1000/fps,blit=False,repeat=False)
    if video:
        if Path(video).suffix.lower()=='.gif':writer=PillowWriter(fps=fps)
        else:
            if not shutil.which('ffmpeg'):raise RuntimeError('MP4 requiere ffmpeg; exporta .gif o instala ffmpeg')
            writer=FFMpegWriter(fps=fps,codec='libx264',extra_args=['-pix_fmt','yuv420p'])
        animation.save(str(video),writer=writer,dpi=100)
    update(len(ix)-1)
    if snapshot:f.savefig(snapshot,dpi=120)
    if show:plt.show()
    elif video or snapshot:plt.close(f)
    return animation
