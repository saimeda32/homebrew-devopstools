.PHONY: validate dry-run

validate:
	./scripts/validate_tools.sh tools.txt

dry-run:
	chmod +x install.sh
	./install.sh --dry-run tools.txt
