import * as admin from 'firebase-admin';
import { processComments } from './commentAnalysis';

admin.initializeApp();

export { processComments }; 