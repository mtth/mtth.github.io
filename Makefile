markdown_paths = $(wildcard src/posts/*.md)
html_paths = $(patsubst src/posts/%.md, pub/posts/%.html, $(markdown_paths))

index.html: src/index.md $(html_paths)
	pandoc -s -o $@ $<

src/index.md: $(markdown_paths)
	./etc/scripts/build-index

pub/posts/%.html: src/posts/%.md
	pandoc -s -o $@ $<

.PHONY: clean
clean:
	rm -r index.html src/index.md pub/posts/*
