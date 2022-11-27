"""Wraps k3d to help with Bazel integration."""

# import argparse
import os
import subprocess

subprocess.run(["which", "k3d"])
binary = os.environ.get('K3D_BINARY')
config = os.environ.get('K3D_CONFIG')
command = os.environ.get('K3D_COMMAND')
operation = os.environ.get('K3D_OPERATION')

print("Binary: {}".format(binary))
print("Config: {}".format(config))
print("Command: {}".format(command))
print("Operation: {}".format(operation))

subprocess.run([binary, "version"])
