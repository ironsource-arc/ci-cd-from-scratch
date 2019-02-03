#!/usr/bin/groovy
package io.zigius;

def environmentNamespace(environment){
  return "${env.KUBERNETES_NAMESPACE}-${environment}"
}

return this;

