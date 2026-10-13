"""Proceso de cálculo cancelable; jamás toca widgets desde el hijo."""
import multiprocessing as mp
import traceback

def _calculate(connection,profile,options):
    try:
        from .experiments import run_experiment
        connection.send(('ok',run_experiment(profile,options)))
    except Exception as exc:connection.send(('error',str(exc),traceback.format_exc()))
    finally:connection.close()

class ExperimentWorker:
    def __init__(self):self.process=None;self.connection=None
    @property
    def busy(self):return self.process is not None
    def start(self,profile,options):
        if self.busy:raise RuntimeError('Ya hay un cálculo en curso')
        ctx=mp.get_context('spawn');parent,child=ctx.Pipe(duplex=False)
        process=ctx.Process(target=_calculate,args=(child,profile,options),daemon=True)
        try:process.start()
        except Exception:parent.close();child.close();raise
        child.close();self.connection=parent;self.process=process
    def poll(self):
        if not self.busy:return None
        if self.connection.poll():
            try:result=self.connection.recv()
            except EOFError:result=('error','El proceso terminó sin resultados')
            self.cancel();return result
        if not self.process.is_alive():
            code=self.process.exitcode;self.cancel();return ('error',f'El proceso terminó sin resultados (código {code})')
        return None
    def cancel(self):
        if self.process is not None:
            if self.process.is_alive():self.process.terminate()
            self.process.join(timeout=2);self.process.close();self.process=None
        if self.connection is not None:self.connection.close();self.connection=None
