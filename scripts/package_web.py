"""Package only the compiled Flutter web release and Firebase hosting configuration."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root=Path(__file__).resolve().parents[1]
release=root/'build/web'
if not (release/'main.dart.js').is_file():
    raise SystemExit('Run npm run build before packaging.')
output=root/'output/vedomax-web-2.0.0.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output,'w',ZIP_DEFLATED,compresslevel=9) as archive:
    for path in sorted(release.rglob('*')):
        if path.is_file():
            archive.write(path,path.relative_to(root).as_posix())
    for name in ['firebase.json','.firebaserc']:
        archive.write(root/name,name)
    archive.writestr('DEPLOY.md',
        '# Vedomax 2.0 – Flutter web\n\n'
        'Extract into a new folder. Sign in to Firebase CLI with an account authorized for project vedomax, '
        'then run `npx firebase-tools deploy --only hosting --project vedomax` from this folder.\n\n'
        'The package contains build/web and hosting configuration, not private environment files. '
        'The existing public Supabase configuration is compiled into the client. '
        'The Vedomax daily database migration is already installed in the connected project. '
        'Publishing this archive updates the public website.\n')
with ZipFile(output) as archive:
    assert archive.testzip() is None
    names=archive.namelist()
    assert 'build/web/main.dart.js' in names and 'firebase.json' in names
    assert all(not Path(name).name.startswith('.env') for name in names)
print(f'{output.name}: {output.stat().st_size:,} bytes; ZIP integrity and environment-file exclusion verified.')
