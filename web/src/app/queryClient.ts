import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query';
import { showErrorAlert } from '../services/errorAlertService';
import { logError } from '../utils/errors';

export const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (error, query) => {
      logError('react_query.query_error', error, {
        queryKey: query.queryKey
      });
      showErrorAlert(error, 'Falha ao carregar dados');
    }
  }),
  mutationCache: new MutationCache({
    onError: (error, _variables, _context, mutation) => {
      logError('react_query.mutation_error', error, {
        mutationKey: mutation.options.mutationKey
      });
    }
  }),
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false
    }
  }
});
