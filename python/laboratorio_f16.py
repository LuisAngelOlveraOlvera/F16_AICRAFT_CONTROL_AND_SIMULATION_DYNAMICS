"""Punto de entrada adicional. Los comandos existentes no se modifican."""
import multiprocessing

if __name__=='__main__':
    multiprocessing.freeze_support()
    from f16py.laboratory.app import main
    main()
