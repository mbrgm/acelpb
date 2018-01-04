with import <nixpkgs> {};
let
  oauth2 = pkgs.python36Packages.buildPythonPackage rec {
    pname = "python-oauth2";
    version = "1.0.1";
    name = "${pname}-${version}";

    doCheck = false;

    src = pkgs.python36Packages.fetchPypi {
      inherit pname version;
      sha256 = "0a1d0qnlgm07wq9r9bbm5jqkqry73w34m87p0141bk76lg7bb0sm";
    };

    meta = with lib; {
      description = "Framework that aims at making it easy to provide authentication via OAuth 2.0 within an application stack";
      homepage =  https://github.com/wndhydrnt/python-oauth2;
      license = lib.licenses.mit;
      maintainers = with maintainers; [ ixxie ];
    };
  };

  myPamela = pkgs.python36Packages.buildPythonPackage rec {
    pname = "pamela";
    version = "0.3.0";
    name = "${pname}-${version}";

    propagatedBuildInputs = [
      pkgs.pam
    ];

    doCheck = true;

    postUnpack = ''
      substituteInPlace $sourceRoot/pamela.py --replace \
      'find_library("pam")' \
      '"${lib.getLib pkgs.pam}/lib/libpam.so"'
    '';

    src = pkgs.python36Packages.fetchPypi {
      inherit pname version;
      sha256 = "0ssxbqsshrm8p642g3h6wsq20z1fsqhpdvqdm827gn6dlr38868y";
    };
  };
in
pkgs.python36Packages.buildPythonApplication rec {
  pname = "jupyterhub";
  version = "0.8.1";
  name = "${pname}-${version}";

  src = pkgs.python36Packages.fetchPypi {
    inherit pname version;
    sha256 = "1766lllqhqripqqinfqgh4fcyxmkzgz3h3a58mx800lqaf6z230h";
  };

  buildInputs = [
    pkgs.nodejs
  ];

  propagatedBuildInputs = [
    (pkgs.python36.withPackages (pythonPackages: with pythonPackages; [
        pycurl
        notebook
        jupyterlab
        myPamela
        alembic
        oauth2
    ]))
  ];

  doCheck = false;

  meta = {
    description = "Create a multi-user Hub which spawns, manages, and proxies multiple instances of the single-user Jupyter notebook server.";
    homepage = http://jupyter.org/;
    license = lib.licenses.bsd3;
    platforms = stdenv.lib.platforms.linux;
  };
}
