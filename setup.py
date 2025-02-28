from setuptools import find_packages, setup

setup(
    name="anonym",
    packages=find_packages(exclude=["anonym_tests"]),
    install_requires=[
        "faker",
        "jsonpath-ng",
        "clickhouse-connect",
        "click",
        "ipaddress",
        "coloredlogs",
        "load_dotenv",
    ],
    extras_require={},
)
