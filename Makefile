GPMLS := ${shell cat pathways.txt | sed -e 's/\(.*\)/gpml\/\1.gpml/' }
WPRDFS := ${shell cat pathways.txt | sed -e 's/\(.*\)/wp\/Human\/\1.ttl/' }
GPMLRDFS := ${shell cat pathways.txt | sed -e 's/\(.*\)/wp\/gpml\/Human\/\1.ttl/' }
REPORTS := ${shell cat pathways.txt | sed -e 's/\(.*\)/reports\/\1.md/' }

all: wikipathways-SARS-CoV-2-rdf-authors.zip wikipathways-SARS-CoV-2-rdf-wp.zip \
     wikipathways-SARS-CoV-2-rdf-gpml.zip

fetch:clean ${GPMLS}

clean:
	@rm -f ${GPMLS}

gpml/%.gpml:
	@echo "Git fetching $@ ..."
	@echo '$@' | sed -e 's/gpml\/\(.*\)\.gpml/\1/' | xargs bash getPathway.sh

wikipathways-SARS-CoV-2-rdf-authors.zip: authors/*
	@rm -f wikipathways-SARS-CoV-2-rdf-authors.zip
	@zip wikipathways-SARS-CoV-2-rdf-authors.zip authors/*

wikipathways-SARS-CoV-2-rdf-wp.zip: ${WPRDFS}
	@rm -f wikipathways-SARS-CoV-2-rdf-wp.zip
	@zip wikipathways-SARS-CoV-2-rdf-wp.zip wp/Human/*

wikipathways-SARS-CoV-2-rdf-gpml.zip: ${GPMLRDFS}
	@rm -f wikipathways-SARS-CoV-2-rdf-gpml.zip
	@zip wikipathways-SARS-CoV-2-rdf-gpml.zip wp/gpml/Human/*

wp/Human/%.ttl: gpml/%.gpml src/java/main/org/wikipathways/covid/CreateRDF.class
	@mkdir -p wp/Human
	@cat "$<.rev" | xargs java -cp src/java/main/.:libs/GPML2RDF-3.0.0-SNAPSHOT-jar-with-dependencies.jar:libs/derby-10.5.3.0_1.jar org.wikipathways.covid.CreateRDF $< | grep -v ".bridge" > $@

wp/gpml/Human/%.ttl: gpml/%.gpml src/java/main/org/wikipathways/covid/CreateGPMLRDF.class
	@mkdir -p wp/gpml/Human
	@cat "$<.rev" | xargs java -cp src/java/main/.:libs/GPML2RDF-3.0.0-SNAPSHOT-jar-with-dependencies.jar:libs/derby-10.5.3.0_1.jar org.wikipathways.covid.CreateGPMLRDF $< | grep -v ".bridge" > $@

src/java/main/org/wikipathways/covid/CreateRDF.class: src/java/main/org/wikipathways/covid/CreateRDF.java
	@echo "Compiling $@ ..."
	@javac -cp libs/GPML2RDF-3.0.0-SNAPSHOT-jar-with-dependencies.jar src/java/main/org/wikipathways/covid/CreateRDF.java

src/java/main/org/wikipathways/covid/CreateGPMLRDF.class: src/java/main/org/wikipathways/covid/CreateGPMLRDF.java
	@echo "Compiling $@ ..."
	@javac -cp libs/GPML2RDF-3.0.0-SNAPSHOT-jar-with-dependencies.jar src/java/main/org/wikipathways/covid/CreateGPMLRDF.java

src/java/main/org/wikipathways/covid/CheckRDF.class: src/java/main/org/wikipathways/covid/CheckRDF.java libs/wikipathways.curator-1-SNAPSHOT-jar-with-dependencies.jar
	@echo "Compiling $@ ..."
	@javac -cp libs/wikipathways.curator-1-SNAPSHOT-jar-with-dependencies.jar src/java/main/org/wikipathways/covid/CheckRDF.java

check: ${REPORTS}

reports/%.md: wp/Human/%.ttl wp/gpml/Human/%.ttl src/java/main/org/wikipathways/covid/CheckRDF.class src/java/main/org/wikipathways/covid/CreateGPMLRDF.class
	@mkdir -p reports
	@java -cp libs/jena-arq-3.16.0.jar:src/java/main/:libs/wikipathways.curator-1-SNAPSHOT-jar-with-dependencies.jar org.wikipathways.covid.CheckRDF $< > $@
