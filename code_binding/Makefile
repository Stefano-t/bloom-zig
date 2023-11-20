.PHONY: clean

clean:
	rm -rf build
	rm -rf dist
	rm -rf *.egg-info/

.PHONY: compile-wheel install test-py

compile-wheel: clean
	python3 setup.py bdist_wheel

install: compile-wheel
	pip install --force-reinstall dist/*.whl

test-py:
	python3 -c "import bloom"
