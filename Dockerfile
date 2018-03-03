# Building Stage
FROM openjdk:8-alpine as Builder

WORKDIR /app/

RUN set -xe \
  && apk add --no-cache subversion ca-certificates openssl \
  && update-ca-certificates \
  && wget https://cs.gmu.edu/~eclab/projects/ecj/ecj.24.tar.gz \
  && tar oxzvf ecj.24.tar.gz \
  && rm ecj.24.tar.gz \
  && svn checkout https://svn.code.sf.net/p/evotutoring/code/trunk/evoparsons evoparsons \
  && svn checkout https://svn.code.sf.net/p/evotutoring/code/trunk/org org \
  && svn checkout https://svn.code.sf.net/p/evotutoring/code/trunk/testing testing \
  && cd .. \
  && cp -r /app/ecj/ec/ /app/ \
  && mv /app/evoparsons/ecj/parsons /app/ec/ \
  && mv /app/evoparsons/ecj/server /app/ec/

RUN set -xe \
  && sed -i 's/hostname = "127.0.0.1"/hostname = "ea"/g' evoparsons/broker/ParsonsBroker.java \
  && sed -i 's/ParsonsBrokerProxy("spell.forest.usf.edu", 1235, "bit.ramapo.edu", 1235)/ParsonsBrokerProxy("spell.forest.usf.edu", 1235, "", 0)/g' evoparsons/psi/PSI.java

RUN set -xe \
  && rm -f *.jar \
  && javac -cp ./ ./evoparsons/*/*.java ./ec/parsons/*.java ./ec/server/*.java ./org/problets/lib/comm/rmi/*.java -target 1.6 -source 1.6 \
  && jar cfm ./Broker.jar ./evoparsons/broker/manifest.mf ./evoparsons/*/*.class ./org/problets/lib/comm/rmi/*.class \
  && jar cfm ./ParsonsProblet.jar ./evoparsons/problet/manifest.mf ./evoparsons/*/*.class ./org/problets/lib/comm/rmi/*.class \
  # && jar cfm ./Relay.jar ./org/problets/lib/comm/rmi/manifest.mf ./evoparsons/broker/ParsonsBrokerConfig.class ./evoparsons/rmishared/*.class  ./org/problets/lib/comm/rmi/*.class \
  # && jar cfm ./Jade.jar ./evoparsons/jade/manifest.mf ./evoparsons/broker/ParsonsBrokerConfig.class ./evoparsons/rmishared/*.class ./jade/*/*.class \
  && jar cfm ./PSI.jar ./evoparsons/psi/manifest.mf ./evoparsons/*/*.class  ./org/problets/lib/comm/rmi/*.class \
  && jar cfm ./ECJ.jar ./ec/parsons/manifest.mf ./ec/server/*.class ./ec/parsons/*.class  ./ec/*.class ./ec/*/*.class ./ec/*/*/*.class  ./evoparsons/rmishared/*.class ./evoparsons/broker/ParsonsBrokerConfig.class ./org/problets/lib/comm/rmi/*.class

# Runtime Stage
FROM openjdk:8-jre-alpine

WORKDIR /app/
COPY --from=Builder /app/*.jar /app/
COPY --from=Builder /app/evoparsons/psi/Transforms /app/Transforms
COPY --from=Builder /app/evoparsons/psi/Programs /app/Programs
COPY --from=Builder /app/evoparsons/broker/config.property.broker /app/
COPY --from=Builder /app/testing/my-config-local-machine.params /app/
COPY --from=Builder /app/testing/simple.params /app/

VOLUME [ "/data" ]
