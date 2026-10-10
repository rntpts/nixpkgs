{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
}:

buildGoModule (finalAttrs: {
  pname = "livekit";
  version = "1.13.9";

  src = fetchFromGitHub {
    owner = "livekit";
    repo = "livekit";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pNPdjqluBSSZ+awUYzzQ+175HpCV+m2EDYBafgvQHTE=";
  };

  vendorHash = "sha256-mUMa1ZNiVXcowJeORWK9s2qc6oTxppbhIyKzvSj8lmM=";

  subPackages = [ "cmd/server" ];

  postInstall = ''
    mv $out/bin/server $out/bin/livekit-server
  '';

  passthru.tests = nixosTests.livekit;

  meta = {
    description = "End-to-end stack for WebRTC. SFU media server and SDKs";
    homepage = "https://livekit.io/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ mgdelacroix ];
    mainProgram = "livekit-server";
  };
})
