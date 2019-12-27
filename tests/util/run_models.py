# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
"""Utilities for running models with different datatypes."""

import tvm
import numpy as np
from tvm import relay
from .change_dtype import change_dtype, convert_ndarray


def run_model(get_workload,
              input_shape,
              src_dtype,
              dst_dtype,
              rtol=0.0001,
              atol=0.0001):
    module, params = get_workload()

    ex = relay.create_executor("graph")

    # Convert the input into the correct format.
    input = tvm.nd.array(np.random.rand(*input_shape).astype(src_dtype))

    correct = relay.create_executor("graph", module).evaluate()(input,
                                                                **params)

    # Simplifying inference is essential right now, as batch norms (which get
    # removed) are broken with custom datatypes.
    module = relay.transform.SimplifyInference()(module)
    expr, params = change_dtype(src_dtype, dst_dtype, module['main'], params,
                                ex)

    input = convert_ndarray(dst_dtype, input, ex)

    # Vectorization is not implemented with custom datatypes.
    with tvm.build_config(disable_vectorize=True):
        result = ex.evaluate(expr)(input, **params)

    tvm.testing.assert_allclose(convert_ndarray(src_dtype, result,
                                                ex).asnumpy(),
                                correct.asnumpy(),
                                rtol=rtol,
                                atol=atol)