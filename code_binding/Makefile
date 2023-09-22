.PHONY: clean

clean:
	rm -fr build
	rm -fr dist

.PHONY: compile_wheel install test-py

compile-wheel: clean
	python3 setup.py bdist_wheel

install: compile-wheel
	pip install --force-reinstall dist/*.whl

test-py:
	python3 -c "import bloom"
