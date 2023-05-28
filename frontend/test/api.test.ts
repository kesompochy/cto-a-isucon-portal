import { API, Auth, graphqlOperation } from 'aws-amplify'

import { describe, test, vi } from 'vitest'

describe('API mock test', () => {
    test('mock', () => {
        const mockFn = vi.fn((a: number) => a * 10)
        mockFn(1)
    })
})