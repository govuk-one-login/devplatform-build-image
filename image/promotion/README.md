# Promotion Stage

The promotion stage of the SAM deployment pipeline is implemented here.

In the promotion stage, a SAM template that has just been successfully deployed and tested is:

* scanned for any dependent resources, copying these to the target environment
* transformed to replace all references specific to the current environment to the target environment
* copied to the target environment to trigger the target environment's pipeline

## Testing

Run the promotion stage's unit tests by running in this directory:

```bash
python -m venv .venv/
source .venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet --requirement requirements.txt
python -m unittest promote_test.py -v
deactivate
```
