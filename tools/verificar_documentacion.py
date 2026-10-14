"""Comprobar la documentación común sin depender de MATLAB ni paquetes Python."""
import re
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]


def main():
    pages = [ROOT / 'README.md', ROOT / 'CONTRIBUTING.md']
    pages.extend(p for p in (ROOT / 'docs').rglob('*.md') if 'superpowers' not in p.parts)
    for page in pages:
        assert page.is_file(), f'Falta {page.relative_to(ROOT)}'
        source = re.sub(r'```.*?```', '', page.read_text(encoding='utf-8'), flags=re.S)
        for target in re.findall(r'\]\(([^)]+)\)', source):
            target = target.split()[0].strip('<>')
            if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith('#'):
                continue
            path = unquote(target.split('#', 1)[0])
            assert (page.parent / path).exists(), f'Enlace roto en {page.relative_to(ROOT)}: {target}'
    for component in ('matlab', 'python'):
        for duplicate in ('README.md', 'LICENSE', 'CONTRIBUTING.md', '.gitignore', '.gitattributes', '.github/workflows/tests.yml'):
            assert not (ROOT / component / duplicate).exists(), f'Configuracion duplicada: {component}/{duplicate}'
    assert not (ROOT / 'python/references/README.md').exists(), 'Las referencias se documentan en docs/REFERENCIAS_NUMERICAS.md'
    assert (ROOT / 'LICENSE').is_file()
    assert (ROOT / '.github/ISSUE_TEMPLATE/bug_report.md').is_file()
    for workflow in ('python.yml', 'matlab.yml'):
        assert (ROOT / '.github/workflows' / workflow).is_file()
    print(f'DOCUMENTACION: PASS ({len(pages)} documentos, enlaces locales y configuracion comun).')


if __name__ == '__main__':
    main()
