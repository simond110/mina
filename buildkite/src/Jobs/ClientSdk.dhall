let Prelude = ../External/Prelude.dhall

let S = ../Lib/SelectFiles.dhall
let Cmd = ../Lib/Cmds.dhall

let Pipeline = ../Pipeline/Dsl.dhall
let JobSpec = ../Pipeline/JobSpec.dhall

let Command = ../Command/Base.dhall
let OpamInit = ../Command/OpamInit.dhall
let Docker = ../Command/Docker/Type.dhall
let Size = ../Command/Size.dhall

in

Pipeline.build
  Pipeline.Config::{
    spec = 
      JobSpec::{
        dirtyWhen = OpamInit.dirtyWhen # [
          S.strictlyStart (S.contains "buildkite/src/Jobs/ClientSdk"),
          S.strictlyStart (S.contains "src")
        ],
        name = "ClientSdk"
      },
    steps = [
      Command.build
        Command.Config::{
          commands = [
            Cmd.run "chmod -R 777 frontend/client_sdk",
            Cmd.runInDocker
              Cmd.Docker::{image = (../Constants/ContainerImages.dhall).codaToolchain}
              "cd frontend/client_sdk && yarn install"
          ]
          , label = "Install Yarn dependencies"
          , key = "install-yarn-deps"
          , target = Size.Small
          , docker = None Docker.Type
        },
      Command.build
        Command.Config::{
          commands = OpamInit.andThenRunInDocker ([] : List Text) "./scripts/client_sdk_unit_tests.sh",
          label = "Build and Test Client SDK",
          key = "client-sdk-unittests",
          target = Size.Medium,
          docker = None Docker.Type
        },
      Command.build
        Command.Config::{
          commands = OpamInit.andThenRunInDocker ([] : List Text) "opam install dune && cd frontend/client_sdk && yarn prepublishOnly",
          label = "Prepublish Client SDK packages",
          key = "prepublish-client-sdk",
          target = Size.Medium,
          docker = None Docker.Type
        }
    ]
  }

